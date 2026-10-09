#include "l1_kernels.h"

#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N_ITER 10000

typedef void (*sscal_fn)(float *, uint64_t, float);

static void sscal_accelerate(float *x, uint64_t n, float alpha)
{
    cblas_sscal((int)n, alpha, x, 1);
}

static const uint64_t test_numbers[] = {
    4, 8, 16, 32, 64, 128, 256, 512, 640, 656, 672, 688,
    704, 720, 736, 752, 768, 784, 800, 816, 832, 896,
    928, 960, 992, 1008, 1024, 1040, 1056, 1088, 1120, 1152,
    1216, 1280, 1536, 2048, 4096, 16384, 65536, 262144
};

static clock_t time_sscal(sscal_fn fn, float *x, uint64_t n)
{
    clock_t start = clock();
    for (int i = 0; i < N_ITER; ++i)
        fn(x, n, -1.0f);
    return clock() - start;
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
    printf("%10s %14s %14s %14s %14s %14s\n", "n", "ASM",
           "NEON", "SME 4xVGx4", "SME 8xVGx4", "Accelerate");
    for (size_t i = 0; i < n_tests; ++i) {
        uint64_t n = test_numbers[i];
        clock_t times[] = {
            time_sscal(sscal_asm, x, n),
            time_sscal(sscal_neon, x, n),
            time_sscal(sscal_sme4xVGx4, x, n),
            time_sscal(sscal_sme8xVGx4, x, n),
            time_sscal(sscal_accelerate, x, n)
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
    return 0;
}
