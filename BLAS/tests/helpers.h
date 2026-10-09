#ifndef TEST_HELPERS_H
#define TEST_HELPERS_H

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define ATOL 1e-3f
#define RTOL 1e-3f
#define MIN -10000.0f
#define MAX 10000.0f

static float *random_vec_float(uint64_t n)
{
    float *vec = malloc(n * sizeof(*vec));
    if (!vec)
        return NULL;

    for (uint64_t i = 0; i < n; ++i)
        vec[i] = MIN + ((float)rand() / RAND_MAX) * (MAX - MIN);
    return vec;
}

static int compare_vec_float(const float *expected, const float *measured,
                             uint64_t n)
{
    int failed = 0;
    for (uint64_t i = 0; i < n; ++i) {
        float diff = fabsf(measured[i] - expected[i]);
        float tolerance = ATOL + RTOL * fabsf(expected[i]);
        if (diff > tolerance) {
            fprintf(stderr,
                    "mismatch at [%llu]: expected %.9g, got %.9g "
                    "(diff %.9g, tolerance %.9g)\n",
                    (unsigned long long)i, expected[i], measured[i],
                    diff, tolerance);
            failed = 1;
        }
    }
    return failed;
}

#endif
