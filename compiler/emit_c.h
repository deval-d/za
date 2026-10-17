#ifndef EMIT_C_H
#define EMIT_C_H

#include "schedule.h"

static void write_c_term(arena *a, size_t *variable_ids, size_t src_tensor_id) {
    if (variable_ids[src_tensor_id] != (size_t)-1) {
        printf("value%zu", variable_ids[src_tensor_id]);
        return;
    }

    switch (a->tensors[src_tensor_id].type) {
        case (_scalar_): printf("input%zu", src_tensor_id);    break;
        case (_vector_): printf("input%zu[i]", src_tensor_id); break;
    }
}

static void write_c_body(arena *a, schedule *s, size_t *variable_ids, int indent_lvl) {
    size_t result_id = s[a->operator_count - 1].output_value_id;
    for (size_t idx = 0; idx < a->operator_count; idx++) { 
        schedule *op = &s[idx];

        if (op->operator == schedule_removed)
            continue;

        size_t variable_id = variable_ids[op->output_value_id];
        bool reuse = variable_id != op->output_value_id;

        printf("%*s%svalue%zu", indent_lvl * 4, "", reuse ? "" : "float ", variable_id);
        switch (op->operator) { 
            case (schedule_mul): { 
                printf(" = "); 
                write_c_term(a, variable_ids, op->input_value_ids[0]);
                printf(" * ");
                write_c_term(a, variable_ids, op->input_value_ids[1]);
                printf(";\n");
                break;
            }
            case (schedule_add): {
                printf(" = "); 
                write_c_term(a, variable_ids, op->input_value_ids[0]);
                printf(" + ");
                write_c_term(a, variable_ids, op->input_value_ids[1]);
                printf(";\n");
                break;
            }
            case (schedule_sub): { 
                printf(" = "); 
                write_c_term(a, variable_ids, op->input_value_ids[0]);
                printf(" - ");
                write_c_term(a, variable_ids, op->input_value_ids[1]);
                printf(";\n");
                break;
            }
            case (schedule_fma): { 
                printf(" = fmaf(");
                write_c_term(a, variable_ids, op->input_value_ids[1]);
                printf(", ");
                write_c_term(a, variable_ids, op->input_value_ids[2]);
                printf(", ");
                write_c_term(a, variable_ids, op->input_value_ids[0]);
                printf(");\n");
                break;
            }
            case (schedule_removed): { 
                continue;
            }
        }
    }

    printf("%*soutput[i] = value%zu;\n", indent_lvl * 4, "", variable_ids[result_id]);
}

static void emit_c(arena *a, schedule *s, size_t *variable_ids, int indent_lvl) {
    printf("%*sfor (; i < length; i++) {\n", indent_lvl * 4, "");
    indent_lvl++;
    write_c_body(a, s, variable_ids, indent_lvl);
    indent_lvl--;
    printf("%*s}\n", indent_lvl * 4, "");
}

#endif
