#include "l1_kernels.h"

#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N_ITER 10000

typedef void (*sswap_fn)(float *, float *, uint64_t);

static void sswap_accelerate(float *x, float *y, uint64_t n)
{
    cblas_sswap((int)n, x, 1, y, 1);
}

static const uint64_t test_numbers[] = {
    4, 8, 16, 32, 64, 128, 256, 320, 384, 448, 472, 496,
    512, 1024, 2048, 4096, 16384, 65536, 262144
};

static clock_t time_sswap(sswap_fn fn, float *x, float *y, uint64_t n)
{
    clock_t start = clock();
    for (int i = 0; i < N_ITER; ++i)
        fn(x, y, n);
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
        free(x); free(y);
        return 1;
    }

    for (uint64_t i = 0; i < max_n; ++i) {
        x[i] = (float)(i % 17) * 0.01f;
        y[i] = (float)(i % 13) * 0.01f;
    }

    puts("Average CPU nanoseconds per call");
    printf("%10s %14s %14s %14s %14s\n", "n", "ASM", "NEON", "SME", "Accelerate");
    for (size_t i = 0; i < n_tests; ++i) {
        uint64_t n = test_numbers[i];
        clock_t times[] = {
            time_sswap(sswap_asm, x, y, n),
            time_sswap(sswap_neon, x, y, n),
            time_sswap(sswap_sme, x, y, n),
            time_sswap(sswap_accelerate, x, y, n)
        };
        printf("%10llu %14.1f %14.1f %14.1f %14.1f\n",
               (unsigned long long)n,
               (double)times[0] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[1] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[2] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[3] * 1e9 / CLOCKS_PER_SEC / N_ITER);
    }

    free(x); free(y);
    return 0;
}
