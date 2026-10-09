#include "l1_kernels.h"

#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N_ITER 10000

typedef void (*saxpy_fn)(const float *, float *, uint64_t, float);

static void saxpy_accelerate(const float *x, float *y, uint64_t n, float alpha)
{
    cblas_saxpy((int)n, alpha, x, 1, y, 1);
}

static const uint64_t test_numbers[] = {
    4, 8, 16, 32, 64, 128, 256, 384, 416, 448, 464, 480, 496,
    504, 508, 512, 516, 520, 528, 544, 552, 560, 568, 576,
    592, 608, 624, 640,
    704, 768, 896, 1024, 2048, 4096, 16384, 65536, 262144
};

static clock_t time_saxpy(saxpy_fn fn, const float *x, float *y, uint64_t n)
{
    clock_t start = clock();
    for (int i = 0; i < N_ITER; ++i)
        fn(x, y, n, 0.5f);
    return clock() - start;
}

int main(void)
{
    const size_t n_tests = sizeof(test_numbers) / sizeof(test_numbers[0]);
    const uint64_t max_n = test_numbers[n_tests - 1];
    float *x = malloc(max_n * sizeof(*x));
    float *y = malloc(max_n * sizeof(*y));
    if (!x || !y) {
        perror("malloc");
        free(x);
        free(y);
        return 1;
    }

    for (uint64_t i = 0; i < max_n; ++i) {
        x[i] = (float)(i % 17) * 0.01f;
        y[i] = (float)(i % 13) * 0.01f;
    }

    puts("Average CPU nanoseconds per call");
    printf("%10s %14s %14s %14s %14s %14s\n", "n", "ASM", "NEON",
           "SME 4xVGx4", "SME 8xVGx4", "Accelerate");
    for (size_t i = 0; i < n_tests; ++i) {
        uint64_t n = test_numbers[i];
        clock_t times[] = {
            time_saxpy(saxpy_asm, x, y, n),
            time_saxpy(saxpy_neon, x, y, n),
            time_saxpy(saxpy_sme4xVGx4, x, y, n),
            time_saxpy(saxpy_sme8xVGx4, x, y, n),
            time_saxpy(saxpy_accelerate, x, y, n)
        };
        printf("%10llu %14.1f %14.1f %14.1f %14.1f %14.1f\n",
               (unsigned long long)n,
               (double)times[0] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[1] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[2] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[3] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[4] * 1e9 / CLOCKS_PER_SEC / N_ITER);
    }

    free(x);
    free(y);
    return 0;
}
