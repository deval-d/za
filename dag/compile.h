#ifndef COMPILE_H
#define COMPILE_H

#include "evaluate.h"
#include "schedule.h"
#include "optimize.h"

static void write_term(arena *a, schedule *s, size_t src_tensor_id, size_t operator_id) { 
    bool calculated = false; 
    for (size_t idx = 0; idx < operator_id; idx++) {
        if (s[idx].operator != schedule_removed &&
            s[idx].output_value_id == src_tensor_id) { 
            calculated = true;
            break; 
        }
    }

    switch (a->tensors[src_tensor_id].type) { 
        case (_scalar_): { 
            if (calculated)
                printf("value%zu", src_tensor_id);
            else 
                printf("input%zu", src_tensor_id);
            break;
        }

        case (_vector_): {
            if (calculated) 
                printf("value%zu", src_tensor_id);
            else 
                printf("input%zu[i]", src_tensor_id);
            break;
        }
    }
}

static void write_function_dec(arena *a) { 
    size_t n_tensors = a->tensor_count; 
    int indent_lvl = 0;

    // function name 
    printf("%*svoid generated(\n", indent_lvl * 4, "");
    
    indent_lvl++; 
    for (size_t idx = 0; idx < n_tensors; idx++) { 
        if (a->tensors[idx].arena_owns == false) { 
            switch (a->tensors[idx].type) {
                case (_scalar_): printf("%*sfloat input%zu,\n",  indent_lvl * 4, "", idx); break; 
                case (_vector_): printf("%*sfloat *input%zu,\n", indent_lvl * 4, "", idx); break;
            }
        }
    }
    printf("%*sfloat *output,\n", indent_lvl * 4, "");
    printf("%*ssize_t length\n", indent_lvl * 4, "");

    indent_lvl--;
    printf(") {\n"); 
}

static errors compile(arena *a) { 
    errors prepare_err = prepare(a);
    if (prepare_err != no_failure)
        return prepare_err;

    size_t n_operators = a->operator_count; 
    if (n_operators == 0)
        return no_operations_failure;

    printf("#include <math.h>\n");
    printf("#include <stddef.h>\n\n"); 
    write_function_dec(a); 

    int indent_lvl = 1; 
    printf("%*sfor (size_t i = 0; i < length; i++) {\n", indent_lvl * 4, "");
    indent_lvl++; 

    schedule* s = make_schedule(a); 
    schedule_analysis sa = make_producer_use_arrays(a, s);
    
    // optimize with FMAs 
    fma_pass(a, s, sa); 

    size_t result_id; 
    for (size_t idx = 0; idx < n_operators; idx++) { 
        schedule *op = &s[idx];

        result_id = op->output_value_id; 
        switch (op->operator) { 
            case (schedule_mul): { 
                printf("%*sfloat value%zu", indent_lvl * 4, "", op->output_value_id);
                printf(" = "); 
                write_term(a, s, op->input_value_ids[0], idx);
                printf(" * ");
                write_term(a, s, op->input_value_ids[1], idx);
                printf(";\n");
                break;
            }
            case (schedule_add): {
                printf("%*sfloat value%zu", indent_lvl * 4, "", op->output_value_id);
                printf(" = "); 
                write_term(a, s, op->input_value_ids[0], idx);
                printf(" + ");
                write_term(a, s, op->input_value_ids[1], idx);
                printf(";\n");
                break;
            }
            case (schedule_sub): { 
                printf("%*sfloat value%zu", indent_lvl * 4, "", op->output_value_id);
                printf(" = "); 
                write_term(a, s, op->input_value_ids[0], idx);
                printf(" - ");
                write_term(a, s, op->input_value_ids[1], idx);
                printf(";\n");
                break;
            }
            case (schedule_fma): { 
                printf("%*sfloat value%zu", indent_lvl * 4, "", op->output_value_id);
                printf(" = fmaf(");
                write_term(a, s, op->input_value_ids[1], idx);
                printf(", ");
                write_term(a, s, op->input_value_ids[2], idx);
                printf(", ");
                write_term(a, s, op->input_value_ids[0], idx);
                printf(");\n");
                break;
            }
            case (schedule_removed): { 
                continue;
            }

            // shouldn't run; already handled from `prepare(a)`
            default:
                return unknown_operation_failure;
        }
    }

    printf("%*soutput[i] = value%zu;\n", indent_lvl * 4, "", result_id);
    indent_lvl--; 
    printf("%*s}\n", indent_lvl * 4, "");
    indent_lvl--;
    printf("%*s}\n", indent_lvl * 4, ""); 

    free(sa.producer);
    free(sa.use_count);
    free_schedule(s, n_operators);

    return no_failure;
}

#endif
