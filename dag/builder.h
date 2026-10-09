#ifndef BUILDER_H
#define BUILDER_H 

#include "node.h"


/// allocates a tensor in the arena 
size_t reserve_tensor(arena *a) { 
    if (a->tensor_count >= a->tensor_capacity) {
        a->tensor_capacity *= 2; 
        a->tensors = realloc(
            a->tensors, 
            a->tensor_capacity * sizeof(tensor)
        ); 
    }

    return a->tensor_count++; 
}

/// allocates an operator in the arena 
size_t reserve_operator(arena *a) { 
    if (a->operator_count >= a->operator_capacity) {
        a->operator_capacity *= 2;
        a->operators = realloc(
            a->operators, 
            a->operator_capacity * sizeof(operator)
        );
    }

    return a->operator_count++; 
}

/// allocates and adds a `scalar` to the arena 
size_t scalar(arena *a, float alpha) { 
    size_t id = reserve_tensor(a); 

    a->tensors[id].type = _scalar_;
    a->tensors[id].data.scalar_data = alpha; 
    a->tensors[id].length = 1; 
    a->tensors[id].arena_owns = false;
    
    return id; 
}

/// allocates an adds a `vector` to the arena
size_t vector(arena *a, float *x, size_t length) { 
    size_t id = reserve_tensor(a); 

    a->tensors[id].type = _vector_; 
    a->tensors[id].data.vector_data = x; 
    a->tensors[id].length = length; 
    a->tensors[id].arena_owns = false; 

    return id; 
}

/// allocates and adds an operator to the arena
size_t create_operator(
    arena *a, 
    operator_t type, 
    size_t* src_tensor_ids,
    size_t  src_count
) { 
    size_t id = reserve_operator(a); 
    size_t dst_id = reserve_tensor(a); 

    a->operators[id].type = type; 
    a->operators[id].src_tensor_ids = src_tensor_ids;
    a->operators[id].dst_tensor_id  = dst_id; 
    a->operators[id].src_count = src_count;
    a->operators[id].dst_tensor_id = dst_id;
    a->tensors[dst_id].arena_owns = true;

    // temporaries 
    a->tensors[dst_id].data.vector_data = NULL; 
    a->tensors[dst_id].type = _vector_; 

    return dst_id;  
}

/// allocates and adds a `mul` operation to the arena 
size_t mul(arena *a, size_t arg0_id, size_t arg1_id) {
    size_t *src_dst_ids = malloc(2 * sizeof(*src_dst_ids)); 
    src_dst_ids[0] = arg0_id;
    src_dst_ids[1] = arg1_id; 

    return create_operator(a, _mul_, src_dst_ids, 2); 
}

/// allocates and adds an `add` operation to the arena
size_t add(arena *a, size_t arg0_id, size_t arg1_id) {
    size_t *src_dst_ids = malloc(2 * sizeof(*src_dst_ids)); 
    src_dst_ids[0] = arg0_id;
    src_dst_ids[1] = arg1_id; 

    return create_operator(a, _add_, src_dst_ids, 2); 
}

/// allocates and adds a `sub` operation to the arena 
size_t sub(arena *a, size_t arg0_id, size_t arg1_id) {
    size_t *src_dst_ids = malloc(2 * sizeof(*src_dst_ids)); 
    src_dst_ids[0] = arg0_id;
    src_dst_ids[1] = arg1_id; 

    return create_operator(a, _sub_, src_dst_ids, 2); 
}


#endif
