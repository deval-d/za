#include "helpers.h"
#include "l1_kernels.h"

#include <string.h>

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 513, 1023}

static void saxpy_ref(const float *x, float *y, uint64_t n, float alpha)
{
    for (uint64_t i = 0; i < n; ++i)
        y[i] = fmaf(alpha, x[i], y[i]);
}

int main(void)
{
    const uint64_t sizes[] = SIZES;
    const float alpha = 0.75f;
    int failed = 0;

    srand(1);
    for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
        uint64_t n = sizes[s];
        float *x = random_vec_float(n);
        float *y0 = random_vec_float(n);
        float *yneon = malloc(n * sizeof(*yneon));
        float *ysme4xVGx4 = malloc(n * sizeof(*ysme4xVGx4));
        float *ysme8xVGx4 = malloc(n * sizeof(*ysme8xVGx4));
        float *yref = malloc(n * sizeof(*yref));
        if (!x || !y0 || !yneon || !ysme4xVGx4 || !ysme8xVGx4 || !yref) {
            fprintf(stderr, "allocation failed for n=%llu\n",
                    (unsigned long long)n);
            free(x);
            free(y0);
            free(yneon);
            free(ysme4xVGx4);
            free(ysme8xVGx4);
            free(yref);
            return 1;
        }

        memcpy(yneon, y0, n * sizeof(*y0));
        memcpy(ysme4xVGx4, y0, n * sizeof(*y0));
        memcpy(ysme8xVGx4, y0, n * sizeof(*y0));
        memcpy(yref, y0, n * sizeof(*y0));

        saxpy_ref(x, yref, n, alpha);
        saxpy_neon(x, yneon, n, alpha);
        saxpy_sme4xVGx4(x, ysme4xVGx4, n, alpha);
        saxpy_sme8xVGx4(x, ysme8xVGx4, n, alpha);

        if (compare_vec_float(yref, yneon, n)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(yref, ysme4xVGx4, n)) {
            fprintf(stderr, "SME 4xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(yref, ysme8xVGx4, n)) {
            fprintf(stderr, "SME 8xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }

        free(x);
        free(y0);
        free(yneon);
        free(ysme4xVGx4);
        free(ysme8xVGx4);
        free(yref);
    }

    if (!failed)
        puts("SAXPY tests passed");
    return failed;
}
