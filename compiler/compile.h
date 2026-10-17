#ifndef COMPILE_H
#define COMPILE_H

#include "../dag/evaluate.h"
#include "schedule.h"
#include "optimize.h"
#include "emit_c.h"
#include "emit_neon.h"

typedef enum {
    compile_scalar,
    compile_neon,
} compile_mode;

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
    printf("%*s) {\n", indent_lvl * 4, "");
}

static errors compile(arena *a, compile_mode mode) {
    if (mode != compile_scalar && mode != compile_neon)
        return num_args_failure;

    errors prepare_err = prepare(a);
    if (prepare_err != no_failure)
        return prepare_err;

    size_t n_operators = a->operator_count;
    if (n_operators == 0)
        return no_operations_failure;

    schedule* s = make_schedule(a); 
    schedule_analysis sa = make_producer_use_arrays(a, s);
    
    // optimize with FMAs 
    fma_pass(a, s, sa); 

    size_t *last_use = make_last_use_array(a, s);
    if (last_use == NULL) {
        free(sa.producer);
        free(sa.use_count);
        free_schedule(s, n_operators);
        return allocation_failure;
    }
    mark_overwrite_inputs(a, s, last_use);

    size_t *variable_ids = make_variable_ids(a, s, last_use);
    if (variable_ids == NULL) {
        free(sa.producer);
        free(sa.use_count);
        free(last_use);
        free_schedule(s, n_operators);
        return allocation_failure;
    }

    printf("#include <math.h>\n");
    printf("#include <stddef.h>\n");

    if (mode == compile_neon)
        printf("#include <arm_neon.h>\n");

    printf("\n");

    if (mode == compile_neon) {
        printf("#define LANES_1 16\n");
        printf("#define LANES_2 4\n\n");
    }

    write_function_dec(a);
    int indent_lvl = 0;
    indent_lvl++;

    printf("%*ssize_t i = 0;\n", indent_lvl * 4, "");
    switch (mode) {
        case (compile_scalar):  emit_c(a, s, variable_ids, indent_lvl); break;
        case (compile_neon): emit_neon(a, s, variable_ids, indent_lvl); break;
    }

    indent_lvl--;
    printf("%*s}\n", indent_lvl * 4, "");

    free(sa.producer);
    free(sa.use_count);
    free(last_use);
    free(variable_ids);
    free_schedule(s, n_operators);

    return no_failure;
}

#endif
