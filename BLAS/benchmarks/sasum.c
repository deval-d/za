#include "l1_kernels.h"

#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N_ITER 10000

typedef float (*sasum_fn)(const float *, uint64_t);

static volatile float benchmark_result;

static float sasum_accelerate(const float *x, uint64_t n)
{
    return cblas_sasum((int)n, x, 1);
}

static const uint64_t test_numbers[] = {
    4, 8, 16, 32, 64, 128, 256, 512, 1024, 1536, 2048,
    3072, 3456, 3712, 3776, 3808, 3840, 3872, 3904, 3936,
    3968, 3984, 4000, 4016,
    4032, 4096, 4160, 4224, 4352, 4480, 4736, 5120, 6144,
    8192, 16384, 65536, 262144
};

static clock_t time_sasum(sasum_fn fn, const float *x, uint64_t n)
{
    float result = 0.0f;
    clock_t start = clock();
    for (int i = 0; i < N_ITER; ++i)
        result += fn(x, n);
    clock_t elapsed = clock() - start;
    benchmark_result = result;
    return elapsed;
}

int main(void)
{
    const size_t n_tests = sizeof(test_numbers) / sizeof(test_numbers[0]);
    const uint64_t max_n = test_numbers[n_tests - 1];
    float *x = malloc(max_n * sizeof(*x));
    if (!x) {
        perror("malloc");
        return 1;
    }

    for (uint64_t i = 0; i < max_n; ++i)
        x[i] = (float)((int)(i % 17) - 8) * 0.01f;

    puts("Average CPU nanoseconds per call");
    printf("%10s %14s %14s %14s %14s\n", "n", "ASM", "NEON",
           "SME 4xVGx4", "Accelerate");
    for (size_t i = 0; i < n_tests; ++i) {
        uint64_t n = test_numbers[i];
        clock_t times[] = {
            time_sasum(sasum_asm, x, n),
            time_sasum(sasum_neon, x, n),
            time_sasum(sasum_sme4xVGx4, x, n),
            time_sasum(sasum_accelerate, x, n)
        };
        printf("%10llu %14.1f %14.1f %14.1f %14.1f\n",
               (unsigned long long)n,
               (double)times[0] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[1] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[2] * 1e9 / CLOCKS_PER_SEC / N_ITER,
               (double)times[3] * 1e9 / CLOCKS_PER_SEC / N_ITER);
    }

    free(x);
    return 0;
}
