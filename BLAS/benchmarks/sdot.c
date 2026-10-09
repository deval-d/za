#include "l1_kernels.h"

#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N_ITER 10000

typedef float (*sdot_fn)(const float *, const float *, uint64_t);

static volatile float benchmark_result;

static float sdot_accelerate(const float *x, const float *y, uint64_t n)
{
    return cblas_sdot((int)n, x, 1, y, 1);
}

static const uint64_t test_numbers[] = {
    4, 8, 16, 32, 64, 128, 256, 512, 1024, 1280, 1408,
    1472, 1504, 1520, 1536, 1544, 1552, 1560, 1568, 1584,
    1600, 1616, 1632, 1648, 1664, 1728, 1792, 1920, 2048, 4096,
    16384, 65536, 262144
};

static clock_t time_sdot(sdot_fn fn, const float *x, const float *y, uint64_t n)
{
    float result = 0.0f;
    clock_t start = clock();
    for (int i = 0; i < N_ITER; ++i)
        result += fn(x, y, n);
    clock_t elapsed = clock() - start;
    benchmark_result = result;
    return elapsed;
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
    printf("%10s %14s %14s %14s %14s\n", "n", "ASM", "NEON",
           "SME 4xVGx4", "Accelerate");
    for (size_t i = 0; i < n_tests; ++i) {
        uint64_t n = test_numbers[i];
        clock_t times[] = {
            time_sdot(sdot_asm, x, y, n),
            time_sdot(sdot_neon, x, y, n),
            time_sdot(sdot_sme4xVGx4, x, y, n),
            time_sdot(sdot_accelerate, x, y, n)
        };
        printf("%10llu %14.1f %14.1f %14.1f %14.1f\n",
               (unsigned long long)n,
               (double)times[0] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[1] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[2] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[3] * 1e9 / CLOCKS_PER_SEC / N_ITER);
    }

    free(x);
    free(y);
    return 0;
}
