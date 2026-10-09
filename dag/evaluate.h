#ifndef EVALUATE_H
#define EVALUATE_H

#include "node.h"

typedef enum { 
    allocation_failure, 
    dimension_failure,
    num_args_failure,
    unknown_operation_failure,
    no_failure,
    out_of_bounds_failure, 
} errors;

errors prepare(arena *a) { 
    size_t n_operators = a->operator_count; 

    for (size_t i = 0; i < n_operators; i++) { 
        operator *op = &a->operators[i]; 

        switch (op->type) { 
            case (_mul_): {
                if (op->src_count != 2)
                    return num_args_failure; 
                if ((op->src_tensor_ids[0] >= a->tensor_count) ||
                    (op->src_tensor_ids[1] >= a->tensor_count)) 
                    return out_of_bounds_failure;

                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]];
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]];

                a->tensors[op->dst_tensor_id].type = _vector_; 
                if (arg0->type == _scalar_ && arg1->type == _scalar_) {
                    op->length = 1;
                    a->tensors[op->dst_tensor_id].type   = _scalar_;
                } else if (arg0->type == _scalar_ && arg1->type == _vector_) {
                    op->length = arg1->length; 
                } else if (arg0->type == _vector_ && arg1->type == _scalar_) { 
                    op->length = arg0->length;
                } else {
                    if (arg0->length != arg1->length) 
                        return dimension_failure; 
                    op->length = arg0->length; 
                }

                a->tensors[op->dst_tensor_id].length = op->length;
                break;
            }

            case (_add_): {
                if (op->src_count != 2)
                    return num_args_failure; 
                if ((op->src_tensor_ids[0] >= a->tensor_count) ||
                    (op->src_tensor_ids[1] >= a->tensor_count)) 
                    return out_of_bounds_failure;

                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]];
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]];

                // add must be scalar + scalar or vector + vector 
                if ((arg0->length != arg1->length) || 
                    (arg0->type != arg1->type))
                    return dimension_failure;

                op->length = arg0->length;
                a->tensors[op->dst_tensor_id].length = op->length; 
                a->tensors[op->dst_tensor_id].type = arg0->type; 
                break;
            }

            case (_sub_): {
                if (op->src_count != 2)
                    return num_args_failure;
                if ((op->src_tensor_ids[0] >= a->tensor_count) ||
                    (op->src_tensor_ids[1] >= a->tensor_count)) 
                    return out_of_bounds_failure;

                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]];
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]]; 

                // sub must be scalar - scalar or vector - vector 
                if ((arg0->length != arg1->length) ||
                    (arg0->type != arg1->type)) 
                    return dimension_failure; 

                op->length = arg0->length;
                a->tensors[op->dst_tensor_id].length = op->length; 
                a->tensors[op->dst_tensor_id].type = arg0->type; 
                break;
            }

            default:
                return unknown_operation_failure; 
        }

        tensor *dst = &a->tensors[op->dst_tensor_id];
        if (dst->type == _vector_ && dst->data.vector_data == NULL) {
            dst->data.vector_data = malloc(op->length * sizeof(*dst->data.vector_data));
            if (dst->data.vector_data == NULL)
                return allocation_failure;
        }
    }
    
    return no_failure; 
}


errors evaluate(arena *a) { 
    errors prepare_err = prepare(a); 
    if (prepare_err != no_failure) 
        return prepare_err; 

    size_t n_operators = a->operator_count; 
    for (size_t k = 0; k < n_operators; k++) { 
        operator *op = &a->operators[k];

        switch (op->type) { 
            case (_mul_): {
                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]]; 
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]];
                tensor *dst  = &a->tensors[op->dst_tensor_id];

                if (arg0->type == _scalar_ && arg1->type == _scalar_) { 
                    dst->data.scalar_data = arg0->data.scalar_data * arg1->data.scalar_data; 
                } else if (arg0->type == _scalar_ && arg1->type == _vector_) { 
                    for (size_t j = 0; j < op->length; j++) 
                        dst->data.vector_data[j] = arg0->data.scalar_data * arg1->data.vector_data[j];
                } else if (arg0->type == _vector_ && arg1->type == _scalar_) {
                    for (size_t j = 0; j < op->length; j++) 
                        dst->data.vector_data[j] = arg1->data.scalar_data * arg0->data.vector_data[j];
                } else { 
                    for (size_t j = 0; j < op->length; j++) 
                        dst->data.vector_data[j] = arg0->data.vector_data[j] * arg1->data.vector_data[j];
                }
                break;
            }

            case (_add_): {
                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]];
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]];
                tensor *dst  = &a->tensors[op->dst_tensor_id]; 

                if (arg0->type == _scalar_ && arg1->type == _scalar_) {
                    dst->data.scalar_data = arg0->data.scalar_data + arg1->data.scalar_data;
                } else { 
                    for (size_t j = 0; j < op->length; j++) 
                        dst->data.vector_data[j] = arg0->data.vector_data[j] + arg1->data.vector_data[j];
                }
                break;
            }

            case (_sub_): {
                tensor *arg0 = &a->tensors[op->src_tensor_ids[0]];
                tensor *arg1 = &a->tensors[op->src_tensor_ids[1]];
                tensor *dst  = &a->tensors[op->dst_tensor_id]; 

                if (arg0->type == _scalar_ && arg1->type == _scalar_) {
                    dst->data.scalar_data = arg0->data.scalar_data - arg1->data.scalar_data;
                } else {
                    for (size_t j = 0; j < op->length; j++) 
                        dst->data.vector_data[j] = arg0->data.vector_data[j] - arg1->data.vector_data[j];
                }
                break;
            }

            // should never run; handled by `prepare(a)`
            default:
                return unknown_operation_failure; 
        }
    }

    return no_failure; 
}


#endif
