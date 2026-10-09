#include "helpers.h"
#include "l1_kernels.h"

#include <string.h>

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 319, 320, 471, 472, 495, 496, 497, 513, 1023, 2048}

static void scopy_ref(const float *x, float *y, uint64_t n)
{
    for (uint64_t i = 0; i < n; ++i)
        y[i] = x[i];
}

int main(void)
{
    const uint64_t sizes[] = SIZES;
    int failed = 0;

    srand(1);
    for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
        uint64_t n = sizes[s];
        float *x = random_vec_float(n);
        float *y0 = random_vec_float(n);
        float *yasm = malloc(n * sizeof(*yasm));
        float *yneon = malloc(n * sizeof(*yneon));
        float *ysme = malloc(n * sizeof(*ysme));
        float *yref = malloc(n * sizeof(*yref));
        if (!x || !y0 || !yasm || !yneon || !ysme || !yref) {
            fprintf(stderr, "allocation failed for n=%llu\n", (unsigned long long)n);
            free(x); free(y0); free(yasm); free(yneon); free(ysme); free(yref);
            return 1;
        }

        memcpy(yasm, y0, n * sizeof(*y0));
        memcpy(yneon, y0, n * sizeof(*y0));
        memcpy(ysme, y0, n * sizeof(*y0));
        memcpy(yref, y0, n * sizeof(*y0));

        scopy_ref(x, yref, n);
        scopy_asm(x, yasm, n);
        scopy_neon(x, yneon, n);
        scopy_sme(x, ysme, n);

        if (compare_vec_float(yref, yasm, n)) {
            fprintf(stderr, "ASM failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(yref, yneon, n)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(yref, ysme, n)) {
            fprintf(stderr, "SME failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }

        free(x); free(y0); free(yasm); free(yneon); free(ysme); free(yref);
    }

    if (!failed)
        puts("SCOPY tests passed");
    return failed;
}
