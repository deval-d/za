#ifndef NODE_H
#define NODE_H

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

// data type 
typedef enum { 
    _scalar, 
    _vector,
} tensor_t; 

// operator type 
typedef enum {
    _mul,
    _add,
    _sub,
} operator_t;

// data struct 
typedef struct {
    tensor_t type; 
    size_t length;
    int owns_data; // Nonzero when the arena must free data.
    float *data;
} tensor; 

// operator struct 
typedef struct { 
    operator_t type;
    size_t* src_tensor_ids;
    size_t dst_tensor_id;
    size_t arg_count;
} operator;

// arena context 
typedef struct {
    operator* operators;
    size_t operator_capacity;
    size_t operator_count;
        
    tensor* tensors;
    size_t tensor_capacity;
    size_t tensor_count;
} arena; 


// arena alloc 
static arena* create_arena(void) { 
    arena *ctx = calloc(1, sizeof(arena));
    ctx->operator_capacity = 32;
    ctx->operators = malloc(ctx->operator_capacity * sizeof(operator));

    ctx->tensor_capacity = 32;
    ctx->tensors = malloc(ctx->tensor_capacity * sizeof(operator));

    return ctx; 
}

// free arena 
static void free_arena(arena *ctx) { 
    for (size_t idx = 0; idx < ctx->operator_count; idx++) 
        free(ctx->operators[idx].src_tensor_ids);
    for (size_t idx = 0; idx < ctx->tensor_count; idx++) { 
        if (ctx->tensors[idx].owns_data) 
            free(ctx->tensors[idx].data);
    }

    free(ctx->operators);
    free(ctx->tensors);
    free(ctx);
}


#endif
