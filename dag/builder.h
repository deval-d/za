#ifndef BUILDER_H
#define BUILDER_H

#include "node.h"

/// allocates a tensor type to the arena
static size_t reserve_tensor(arena *ctx) { 
    if (ctx->tensor_count >= ctx->tensor_capacity) { 
        ctx->tensor_capacity *= 2;
        ctx->tensors = realloc(
            ctx->tensors, 
            ctx->tensor_capacity * sizeof(tensor)
        );
    }

    return ctx->tensor_count++; 
}

/// allocates an operator type to the arena 
static size_t reserve_operator(arena *ctx) { 
    if (ctx->operator_count >= ctx->operator_capacity) { 
        ctx->operator_capacity *= 2;
        ctx->operators = realloc(
            ctx->operators, 
            ctx->operator_capacity * sizeof(operator)
        );
    }

    return ctx->operator_count++; 
}


/// adds an arena-owned scalar to the arena 
///
/// returns its position in the arena 
static size_t scalar(arena *ctx, float alpha) { 
    // if this fails i am sorry 
    float *data = malloc(sizeof(*data));
    *data = alpha; 

    size_t id = reserve_tensor(ctx);
    ctx->tensors[id] = (tensor) { 
        .type = _scalar, 
        .length = 1, 
        .owns_data = 1, 
        .data = data, 
    };

    return id; 
}

/// adds a caller-owned vector to the arena
///
/// returns its position in the arena 
static size_t vector(arena *ctx, float *x, size_t length) { 
    size_t id = reserve_tensor(ctx);

    ctx->tensors[id] = (tensor) {
        .type = _vector,
        .length = length,
        .owns_data = 0,
        .data = x, 
    };

    return id; 
}


/// adds an operator to the arena
///
/// returns the position of its output in the arena
static size_t op(arena *ctx, operator_t operator, size_t arg0, size_t arg1) { 
    size_t operator_id = reserve_operator(ctx);
    size_t dst_tensor_id = reserve_tensor(ctx);
    ctx->tensors[dst_tensor_id] = (tensor) {
        .owns_data = 1,
        .data = NULL,
        .length = 0,
        .type = _scalar,
    };

    ctx->operators[operator_id].type = operator; 
    ctx->operators[operator_id].src_tensor_ids = malloc(
        2 * sizeof(*(ctx->operators[operator_id].src_tensor_ids))
    );
    ctx->operators[operator_id].src_tensor_ids[0] = arg0;
    ctx->operators[operator_id].src_tensor_ids[1] = arg1; 
    ctx->operators[operator_id].arg_count = 2;
    ctx->operators[operator_id].dst_tensor_id = dst_tensor_id;

    return dst_tensor_id; 
}

/// adds `mul` op to the arena 
static size_t mul(arena *ctx, size_t a, size_t b) { 
    return op(ctx, _mul, a, b);
} 
/// adds `add` op to the arena 
static size_t add(arena *ctx, size_t a, size_t b) {
    return op(ctx, _add, a, b); 
}
/// adds `sub` op to the arena 
static size_t sub(arena *ctx, size_t a, size_t b) { 
    return op(ctx, _sub, a, b); 
}


#endif
