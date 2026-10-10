#ifndef COMPILE_H
#define COMPILE_H

#include "evaluate.h"

void write_input(arena *a, size_t src_tensor_id, size_t operator_id) { 
    bool calculated = false; 
    for (size_t idx = 0; idx < operator_id; idx++) {
        if (a->operators[idx].dst_tensor_id == src_tensor_id) { 
            calculated = true;
            break; 
        }
    }

    switch (a->tensors[src_tensor_id].type) { 
        case (_scalar_): { 
            if (calculated) printf("value%zu", src_tensor_id); 
            else printf("input%zu", src_tensor_id);
            break;
        }

        case (_vector_): {
            if (calculated) printf("value%zu", src_tensor_id); 
            else printf("input%zu[i]", src_tensor_id);

            break;
        }
    }
}

void write_arguments(arena *a) { 
    size_t n_tensors = a->tensor_count; 

    for (size_t idx = 0; idx < n_tensors; idx++) { 
        if (a->tensors[idx].arena_owns == false) { 
            switch (a->tensors[idx].type) { 
                case (_scalar_): printf("    float input%zu,\n", idx); break;
                case (_vector_): printf("    const float *input%zu,\n", idx); break;
            }
        }   
    }
}

errors compile(arena *a) { 
    errors prepare_err = prepare(a);
    if (prepare_err != no_failure)
        return prepare_err; 

    printf("#include <stddef.h>\n\n"); 
    printf("void generated(\n");
    write_arguments(a);
    printf("    float *output,\n");
    printf("    size_t length\n");
    printf(") {\n");
    printf("    for (size_t i = 0; i < length; i++) {\n");

    size_t n_operators = a->operator_count; 

    if (n_operators == 0)
        return no_operations_failure;

    size_t result_id; 
    for (size_t idx = 0; idx < n_operators; idx++) { 
        operator *op = &a->operators[idx]; 

        result_id = op->dst_tensor_id; 
        switch (op->type) { 
            case (_mul_): { 
                printf("        float value%zu", op->dst_tensor_id);
                printf(" = "); 
                write_input(a, op->src_tensor_ids[0], idx);
                printf(" * ");
                write_input(a, op->src_tensor_ids[1], idx);
                printf(";\n");
                break;
            }
            case (_add_): {
                printf("        float value%zu", op->dst_tensor_id);
                printf(" = "); 
                write_input(a, op->src_tensor_ids[0], idx);
                printf(" + ");
                write_input(a, op->src_tensor_ids[1], idx);
                printf(";\n");
                break;
            }
            case (_sub_): { 
                printf("        float value%zu", op->dst_tensor_id);
                printf(" = "); 
                write_input(a, op->src_tensor_ids[0], idx);
                printf(" - ");
                write_input(a, op->src_tensor_ids[1], idx);
                printf(";\n");
                break;
            }

            // shouldn't run; already handled from `prepare(a)`
            default:
                return unknown_operation_failure;
        }
    }

    printf("        output[i] = value%zu;\n", result_id);
    printf("    }\n");
    printf("}\n"); 

    return no_failure;
}

#endif
