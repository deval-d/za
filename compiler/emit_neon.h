#ifndef EMIT_NEON_H
#define EMIT_NEON_H

#include "emit_c.h"

static void write_neon_variable(size_t variable_id, size_t vector, size_t n_vectors) {
    printf("value%zu", variable_id);
    if (n_vectors > 1)
        printf("_%zu", vector);
}

static void write_neon_term(
    arena *a,
    size_t *variable_ids,
    size_t src_tensor_id,
    size_t vector,
    size_t n_vectors
) {
    if (variable_ids[src_tensor_id] != (size_t)-1) {
        write_neon_variable(variable_ids[src_tensor_id], vector, n_vectors);
        return;
    }

    switch (a->tensors[src_tensor_id].type) {
        case (_scalar_): printf("vdupq_n_f32(input%zu)", src_tensor_id); break;
        case (_vector_): {
            printf("vld1q_f32(input%zu + i", src_tensor_id);
            if (vector != 0)
                printf(" + %zu", vector * 4);
            printf(")");
            break;
        }
    }
}

static void write_neon_body(
    arena *a, 
    schedule *s, 
    size_t *variable_ids, 
    size_t n_vectors, 
    int indent_lvl
) {
    for (size_t idx = 0; idx < a->operator_count; idx++) {
        schedule *op = &s[idx];
        if (op->operator == schedule_removed)
            continue;

        size_t variable_id = variable_ids[op->output_value_id];
        bool reuse = variable_id != op->output_value_id;
        for (size_t vector = 0; vector < n_vectors; vector++) {
            printf("%*s%s", indent_lvl * 4, "", reuse ? "" : "float32x4_t ");
            write_neon_variable(variable_id, vector, n_vectors);
            printf(" = ");

            switch (op->operator) {
                case (schedule_mul): printf("vmulq_f32("); break;
                case (schedule_add): printf("vaddq_f32("); break;
                case (schedule_sub): printf("vsubq_f32("); break;
                case (schedule_fma): printf("vfmaq_f32("); break;
                case (schedule_removed): break;
            }

            printf("\n");
            indent_lvl++;
            for (size_t input = 0; input < op->input_count; input++) {
                printf("%*s", indent_lvl * 4, "");

                write_neon_term(
                    a, 
                    variable_ids,
                    op->input_value_ids[input],
                    vector,
                    n_vectors
                );

                printf("%s\n", input + 1 < op->input_count ? "," : "");
            }
            indent_lvl--;
            printf("%*s);\n\n", indent_lvl * 4, "");
        }
    }

    size_t result_id = s[a->operator_count - 1].output_value_id;
    for (size_t vector = 0; vector < n_vectors; vector++) {
        printf("%*svst1q_f32(output + i", indent_lvl * 4, "");

        if (vector != 0)
            printf(" + %zu", vector * 4);

        printf(", ");
        write_neon_variable(variable_ids[result_id], vector, n_vectors);
        printf(");\n");
    }
}

static void emit_neon(arena *a, schedule *s, size_t *variable_ids, int indent_lvl) {
    printf("%*sfor (; i + LANES_1 <= length; i+=LANES_1) {\n", indent_lvl * 4, "");
    indent_lvl++;

    write_neon_body(a, s, variable_ids, 4, indent_lvl);
    indent_lvl--;

    printf("%*s}\n\n", indent_lvl * 4, "");
    printf("%*sfor (; i + LANES_2 <= length; i+=LANES_2) {\n", indent_lvl * 4, "");
    indent_lvl++;

    write_neon_body(a, s, variable_ids, 1, indent_lvl);
    indent_lvl--;

    printf("%*s}\n\n", indent_lvl * 4, "");
    emit_c(a, s, variable_ids, indent_lvl);
}

#endif
