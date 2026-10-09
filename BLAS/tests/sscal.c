#include "helpers.h"
#include "l1_kernels.h"

#include <string.h>

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 513, 1023}

static void sscal_ref(float *x, uint64_t n, float alpha)
{
    for (uint64_t i = 0; i < n; ++i)
        x[i] *= alpha;
}

int main(void)
{
    const uint64_t sizes[] = SIZES;
    const float alpha = 0.75f;
    int failed = 0;

    srand(1);
    for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
        uint64_t n = sizes[s];
        float *x0 = random_vec_float(n);
        float *xasm = malloc(n * sizeof(*xasm));
        float *xneon = malloc(n * sizeof(*xneon));
        float *xsme4xVGx4 = malloc(n * sizeof(*xsme4xVGx4));
        float *xsme8xVGx4 = malloc(n * sizeof(*xsme8xVGx4));
        float *xref = malloc(n * sizeof(*xref));
        if (!x0 || !xasm || !xneon || !xsme4xVGx4 || !xsme8xVGx4 || !xref) {
            fprintf(stderr, "allocation failed for n=%llu\n",
                    (unsigned long long)n);
            free(x0);
            free(xasm);
            free(xneon);
            free(xsme4xVGx4);
            free(xsme8xVGx4);
            free(xref);
            return 1;
        }

        memcpy(xasm, x0, n * sizeof(*x0));
        memcpy(xneon, x0, n * sizeof(*x0));
        memcpy(xsme4xVGx4, x0, n * sizeof(*x0));
        memcpy(xsme8xVGx4, x0, n * sizeof(*x0));
        memcpy(xref, x0, n * sizeof(*x0));

        sscal_ref(xref, n, alpha);
        sscal_asm(xasm, n, alpha);
        sscal_neon(xneon, n, alpha);
        sscal_sme4xVGx4(xsme4xVGx4, n, alpha);
        sscal_sme8xVGx4(xsme8xVGx4, n, alpha);

        if (compare_vec_float(xref, xasm, n)) {
            fprintf(stderr, "ASM failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(xref, xneon, n)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(xref, xsme4xVGx4, n)) {
            fprintf(stderr, "SME 4xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(xref, xsme8xVGx4, n)) {
            fprintf(stderr, "SME 8xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }

        free(x0);
        free(xasm);
        free(xneon);
        free(xsme4xVGx4);
        free(xsme8xVGx4);
        free(xref);
    }

    if (!failed)
        puts("SSCAL tests passed");
    return failed;
}
