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
        schedule[idx].input_value_ids = malloc(op->src_count * sizeof(*op->src_tensor_ids));

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
    for (size_t idx = 0; idx < n_operations; idx++)
        free(s[idx].input_value_ids);
    free(s);
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
