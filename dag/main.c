#include "node.h"
#include "builder.h"
#include "evaluate.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>

float* random_vec_float(size_t length) {
    float* buffer = malloc(length * sizeof(float)); 
    if (buffer == NULL) {
        perror("Allocation failed");
        exit(EXIT_FAILURE);
    }
    for (size_t idx = 0; idx < length; idx++) {
        buffer[idx] = (float)rand() / (float)RAND_MAX; 
    }
    return buffer; 
}

int main(void) {
    float alpha = 3.1415926f; 
    size_t length = 10000; 
    
    float* x_data = random_vec_float(length);
    float* y_data = random_vec_float(length);
    
    float* y_ref = malloc(length * sizeof(float));
    memcpy(y_ref, y_data, length * sizeof(float));

    for (size_t idx = 0; idx < length; idx++) { 
        y_ref[idx] += alpha * x_data[idx];
    }

    arena* ctx = create_arena();

    size_t alpha_id = scalar(ctx, alpha);
    size_t x_id     = vector(ctx, x_data, length);
    size_t y_id     = vector(ctx, y_data, length);

    size_t mul_id   = mul(ctx, alpha_id, x_id);
    size_t saxpy_id = add(ctx, y_id, mul_id); 

    float* compiler_output = NULL;
    ast_status status = evaluate(ctx, &compiler_output);

    if (status != success) {
        fprintf(stderr, "Compilation aborted! Error code received: %d\n", status);
        
        free(x_data); free(y_data); free(y_ref);
        free_arena(ctx); 
        return EXIT_FAILURE;
    }

    float epsilon = 1e-3f; 
    for (size_t idx = 0; idx < length; idx++) {
        float diff = fabsf(compiler_output[idx] - y_ref[idx]);
        if (diff >= epsilon + epsilon * fabsf(y_ref[idx])) {
            fprintf(stderr, "Verification Failure at index %zu: DAG calculated %f, reference calculated %f\n", 
                    idx, compiler_output[idx], y_ref[idx]);
            assert(0 && "Numerical mismatch discovered.");
        }
    }

    printf("Success! SAXPY verification passed across all %zu array elements.\n", length);

    free(x_data);
    free(y_data);
    free(y_ref);
    free_arena(ctx);

    return EXIT_SUCCESS;
}
