#ifndef SCHEDULE_H
#define SCHEDULE_H

#include "../dag/node.h"
#include <string.h>

// operations the compiler has access to 
typedef enum { 
    schedule_add, 
    schedule_sub,
    schedule_mul,

    // inputs[0] + inputs[1] * inputs[2] 
    schedule_fma,
    schedule_removed, 
} schedule_operator_t; 

typedef struct { 
    schedule_operator_t operator;
    size_t *input_value_ids;
    size_t output_value_id;
    size_t input_count; 
    bool *can_overwrite_input;
} schedule; 

typedef struct { 
    size_t *producer;
    size_t *use_count;
} schedule_analysis;

static schedule_operator_t map_operator(operator_t eval_operator) { 
    switch (eval_operator) { 
        case (_mul_): return schedule_mul; 
        case (_add_): return schedule_add;
        case (_sub_): return schedule_sub;
        
        // shouldn't run. `prepare(a)` runs at beginning of `compile(a)`
        default: return schedule_removed; 
    }
}

/// generates an instruction schedule from the arena 
/// to be used by the compiler to make optimization passes 
static schedule* make_schedule(arena *a) { 
    size_t n_operations = a->operator_count; 
    schedule *schedule = malloc(n_operations * sizeof(*schedule));

    for (size_t idx = 0; idx < n_operations; idx++) {
        operator *op = &a->operators[idx]; 
        schedule[idx].operator = map_operator(op->type);
        schedule[idx].input_count = op->src_count;
        schedule[idx].can_overwrite_input = calloc(
            op->src_count,
            sizeof(*schedule[idx].can_overwrite_input)
        );
        schedule[idx].input_value_ids = malloc(
            op->src_count * sizeof(*op->src_tensor_ids)
        );

        memcpy(
            schedule[idx].input_value_ids, 
            op->src_tensor_ids,
            op->src_count * sizeof(*op->src_tensor_ids)
        );

        schedule[idx].output_value_id = op->dst_tensor_id; 
    }

    return schedule; 
}

/// frees the schedule
static void free_schedule(schedule *s, size_t n_operations) {
    for (size_t idx = 0; idx < n_operations; idx++) {
        free(s[idx].input_value_ids);
        free(s[idx].can_overwrite_input);
    }
    free(s);
}

/// records the final read of each tensor in the current schedule
static size_t *make_last_use_array(arena *a, schedule *s) {
    size_t *last_use = malloc(a->tensor_count * sizeof(*last_use));
    if (last_use == NULL)
        return NULL;

    // -1 marks unused 
    for (size_t id = 0; id < a->tensor_count; id++)
        last_use[id] = -1;

    for (size_t idx = 0; idx < a->operator_count; idx++) {
        if (s[idx].operator == schedule_removed)
            continue;

        for (size_t input = 0; input < s[idx].input_count; input++)
            last_use[s[idx].input_value_ids[input]] = idx;
    }

    // last result shouldn't be marked as unused
    if (a->operator_count != 0)
        last_use[s[a->operator_count - 1].output_value_id] = a->operator_count;

    return last_use;
}

/// marks overwrite candidates without choosing storage for the result
/// run after `prepare(a)` and optimization
static void mark_overwrite_inputs(arena *a, schedule *s, size_t *last_use) {
    for (size_t idx = 0; idx < a->operator_count; idx++) {
        schedule *op = &s[idx];

        for (size_t input = 0; input < op->input_count; input++)
            op->can_overwrite_input[input] = false;

        if (op->operator == schedule_removed)
            continue;

        tensor *dst = &a->tensors[op->output_value_id];
        for (size_t input = 0; input < op->input_count; input++) {
            size_t value_id = op->input_value_ids[input];
            tensor *src = &a->tensors[value_id];

            // a broadcast scalar can't hold a vector result
            op->can_overwrite_input[input] = last_use[value_id] == idx &&
                src->type == dst->type && src->length == dst->length;
        }
    }
}

static size_t *make_variable_ids(arena *a, schedule *s, size_t *last_use) {
    size_t *variable_ids = malloc(a->tensor_count * sizeof(*variable_ids));
    if (variable_ids == NULL)
        return NULL;

    size_t *owners = malloc(a->tensor_count * sizeof(*owners));
    if (owners == NULL) {
        free(variable_ids);
        return NULL;
    }

    for (size_t id = 0; id < a->tensor_count; id++) {
        variable_ids[id] = -1;
        owners[id] = -1;
    }

    for (size_t idx = 0; idx < a->operator_count; idx++) {
        schedule *op = &s[idx];
        if (op->operator == schedule_removed)
            continue;

        size_t variable_id = op->output_value_id;
        for (size_t input = 0; input < op->input_count; input++) {
            size_t value_id = op->input_value_ids[input];
            if (op->can_overwrite_input[input] &&
                variable_ids[value_id] != (size_t)-1) {
                variable_id = variable_ids[value_id];
                break;
            }
        }

        if (variable_id == op->output_value_id) {
            tensor *dst = &a->tensors[op->output_value_id];
            for (size_t id = 0; id < a->tensor_count; id++) {
                size_t owner_id = owners[id];
                if (owner_id == (size_t)-1)
                    continue;

                tensor *src = &a->tensors[owner_id];
                if ((last_use[owner_id] == (size_t)-1 || last_use[owner_id] < idx) &&
                    src->type == dst->type && src->length == dst->length) {
                    variable_id = id;
                    break;
                }
            }
        }
        variable_ids[op->output_value_id] = variable_id;
        owners[variable_id] = op->output_value_id;
    }

    free(owners);
    return variable_ids;
}

static schedule_analysis make_producer_use_arrays(arena *a, schedule *s) { 
    size_t n_operations = a->operator_count; 
    size_t n_tensors    = a->tensor_count; 

    size_t *producer  = malloc(n_tensors * sizeof(*producer));
    size_t *use_count = calloc(n_tensors, sizeof(*use_count)); 

    // n_operations marks values with no producer
    for (size_t idx = 0; idx < n_tensors; idx++)
        producer[idx] = n_operations;

    for (size_t idx = 0; idx < n_operations; idx++) { 
        schedule *entry = &s[idx];

        if (entry->operator == schedule_removed)
            continue; 

        size_t *input_value_ids = entry->input_value_ids;
        size_t output_value_id  = entry->output_value_id;

        producer[output_value_id] = idx;
        for (size_t input = 0; input < entry->input_count; input++)
            use_count[input_value_ids[input]]++;
    }


    return (schedule_analysis) { 
        .producer = producer, 
        .use_count = use_count
    }; 
}


#endif
