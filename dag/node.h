#ifndef NODE_H
#define NODE_H 

#include <stdio.h>
#include <stdlib.h> 
#include <assert.h>
#include <stdbool.h>

/// operator variant 
typedef enum { 
    _add_, 
    _sub_,
    _mul_, 
} operator_t;

// data variant 
typedef enum {
    _scalar_, 
    _vector_,
} tensor_t;

// operator node/type 
typedef struct { 
    operator_t type;

    size_t* src_tensor_ids;
    size_t  dst_tensor_id;
    size_t length; 
    size_t  src_count;
} operator; 

// tensor node/type 
typedef struct { 
    tensor_t type; 
    
    union { 
        float scalar_data;
        float *vector_data;
    } data; 

    size_t length; 
    bool arena_owns; 
} tensor; 

// arena of operators and tensors  
typedef struct { 
    operator* operators;
    size_t operator_count;
    size_t operator_capacity;

    tensor* tensors;
    size_t tensor_count; 
    size_t tensor_capacity;
} arena; 


/// creates an arena 
///
/// operator_capacity = 32;
/// tensor_capacity = 32; 
arena* create_arena(void) { 
    arena* a = calloc(1, sizeof(arena));

    a->operator_capacity = 32;
    a->tensor_capacity = 32;
    a->operators = malloc(a->operator_capacity * sizeof(operator));
    a->tensors   = malloc(a->tensor_capacity   * sizeof(tensor)); 

    return a;
}

/// frees an arena; everything but caller-owned data
void free_arena(arena* a) { 
    size_t n_operators = a->operator_count;
    size_t n_tensors   = a->tensor_count; 

    for (size_t i = 0; i < n_operators; i++) {
        free(a->operators[i].src_tensor_ids);
    }

    for (size_t j = 0; j < n_tensors; j++) { 
        if (a->tensors[j].arena_owns && a->tensors[j].type == _vector_)
            free(a->tensors[j].data.vector_data); 
    }

    free(a->operators);
    free(a->tensors);
    free(a); 
}


#endif
