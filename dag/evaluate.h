#ifndef EVALUATE_H
#define EVALUATE_H

#include "node.h"

// error handling 
typedef enum { 
    failed_alloc, 
    unallocated_input, 
    dimension_mismatch,
    invalid_tensor_idx, 
    invalid_arg_count,
    unknown_operation,
    success, 
} ast_status; 


/// pre-validates lengths and memory allocations 
/// before evaluation
ast_status prepare(arena* ctx) { 
    operator* operators = ctx->operators;
    tensor* tensors = ctx->tensors; 

    for (size_t idx = 0; idx < ctx->operator_count; idx++) { 
        operator* op = &operators[idx];

        switch (op->type) {
            case _mul:
            case _add: 
            case _sub:
                if (op->arg_count != 2) {
                    fprintf(
                        stderr,
                        "operator at index %zu requires 2 arguments.\n",
                        idx
                    );
                    return invalid_arg_count; 
                }
                break;
            default:
                fprintf(stderr, "unknown operation.\n");
                return unknown_operation; 
        }

        // out of bound failure 
        if (op->src_tensor_ids[0] >= ctx->tensor_count || 
            op->src_tensor_ids[1] >= ctx->tensor_count) {
            fprintf(
                stderr,
                "operator at index %zu accesses inputs not in the arena.\n",
                idx
            );
            return invalid_tensor_idx; 
        }

        tensor* arg0 = &tensors[op->src_tensor_ids[0]];
        tensor* arg1 = &tensors[op->src_tensor_ids[1]];
        tensor* out  = &tensors[op->dst_tensor_id]; 
        out->type = (arg0->type == _scalar && arg1->type == _scalar)
                  ? _scalar
                  : _vector;

        // zero length input failure
        if (arg0->length == 0 || arg1->length == 0) {
            fprintf(
                stderr,
                "operator at index %zu contains zero length inputs.\n",
                idx
            );
            return dimension_mismatch;
        }

        // unallocated input failure 
        if ((arg0->data == NULL && !arg0->owns_data) || 
            (arg1->data == NULL && !arg1->owns_data)) {
            fprintf(
                stderr,
                "operator at index %zu contains unallocated inputs.\n",
                idx
            ); 
            return unallocated_input; 
        }

        size_t length;
        if (op->type == _mul && arg0->type == _scalar) {
            length = arg1->length;
        } else if (op->type == _mul && arg1->type == _scalar) {
            length = arg0->length;
        } else {
            if (arg0->length != arg1->length || arg0->type != arg1->type) {
                fprintf(stderr, "operator at index %zu has mismatched inputs.\n", idx);
                return dimension_mismatch;
            }
            length = arg0->length;
        }

        if (out->data == NULL || out->length != length) {
            float *data = realloc(out->data, length * sizeof(*data));
            if (data == NULL) {
                fprintf(stderr, "failed allocation.\n");
                return failed_alloc;
            }
            out->data = data;
        }
        out->length = length;
    }

    // all lengths are consistent  
    return success; 
}


/// evaluates the arena 
ast_status evaluate(arena* ctx, float **out_final) {
    ast_status validation = prepare(ctx); 
    if (validation != success) {
        printf("execution aborted \n");
        return validation;
    }

    operator* operators = ctx->operators; 
    tensor* tensors = ctx->tensors;
    size_t n_operators = ctx->operator_count;

    for (size_t idx = 0; idx < n_operators; idx++) { 
        operator* op = &operators[idx]; 
        tensor *arg0 = &tensors[op->src_tensor_ids[0]];
        tensor *arg1 = &tensors[op->src_tensor_ids[1]]; 
        tensor *out  = &tensors[op->dst_tensor_id];

        switch (op->type) {
            case (_mul): {
                if (arg0->type == _scalar && arg1->type == _scalar) {
                    out->data[0] = *arg0->data * *arg1->data;
                } else if (arg0->type == _scalar && arg1->type == _vector) {
                    for (size_t i = 0; i < out->length; i++) 
                        out->data[i] = arg0->data[0] * arg1->data[i];
                } else if (arg0->type == _vector && arg1->type == _scalar) {
                    for (size_t j = 0; j < out->length; j++) 
                        out->data[j] = arg1->data[0] * arg0->data[j];
                } else {
                    // two vectors 
                    for (size_t k = 0; k < out->length; k++)
                        out->data[k] = arg0->data[k] * arg1->data[k];
                }

                break;
            }

            case (_add): {
                for (size_t i = 0; i < out->length; i++) 
                    out->data[i] = arg0->data[i] + arg1->data[i];

                break;
            }

            case (_sub): {
                for (size_t i = 0; i < out->length; i++) 
                    out->data[i] = arg0->data[i] - arg1->data[i];
                break;
            }

            default: {
                // should never run; already handled by `prepare()`
                fprintf(stderr, "unknown operation.\n");
                return unknown_operation; 
            }
        }
    }

    if (n_operators > 0) { 
        size_t final_dst_id = operators[n_operators - 1].dst_tensor_id; 
        *out_final = tensors[final_dst_id].data; 
    }

    return success; 
}


#endif 
