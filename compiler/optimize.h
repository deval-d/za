#ifndef OPTIMIZE_H
#define OPTIMIZE_H 

#include "../dag/node.h"
#include "schedule.h" 

static void fma_pass(arena* a, schedule* s, schedule_analysis sa) { 
    size_t n_operations = a->operator_count;

    for (size_t idx = 0; idx < n_operations; idx++) { 
        if (s[idx].operator != schedule_add) 
            continue; 

        bool candidate[2] = {false, false}; 
        for (size_t input = 0; input < 2; input++) { 
            size_t value_id = s[idx].input_value_ids[input];
            size_t producer_id = sa.producer[value_id]; 

            if (producer_id == n_operations)
                // is a user input, not from an op 
                continue; 

            candidate[input] = s[producer_id].operator == schedule_mul; 
        }

        size_t chosen; 
        if (candidate[0]) 
            chosen = 0;
        else if (candidate[1])
            chosen = 1;
        else 
            continue; 

        size_t mul_res_id = s[idx].input_value_ids[chosen]; 
        size_t mul_op_id  = sa.producer[mul_res_id];
        size_t mul_entry0 = s[mul_op_id].input_value_ids[0]; 
        size_t mul_entry1 = s[mul_op_id].input_value_ids[1]; 
        
        size_t other_id = chosen == 0 ? 1 : 0; 
        size_t other_entry = s[idx].input_value_ids[other_id];

        // replace the mul + add with an fma in the schedule 
        size_t *fma_inputs = malloc(3 * sizeof(*fma_inputs));
        fma_inputs[0] = other_entry; 
        fma_inputs[1] = mul_entry0;
        fma_inputs[2] = mul_entry1; 

        sa.use_count[mul_res_id]--;
        if (sa.use_count[mul_res_id] == 0)
            s[mul_op_id].operator = schedule_removed; 

        s[idx].operator = schedule_fma;
        free(s[idx].input_value_ids);
        s[idx].input_value_ids = fma_inputs; 
        s[idx].input_count = 3; 
        free(s[idx].can_overwrite_input);
        s[idx].can_overwrite_input = calloc(
            s[idx].input_count, 
            sizeof(*s[idx].can_overwrite_input)
        );
        // leave s[idx].output_value_id unchanged   
    }
}


#endif 
