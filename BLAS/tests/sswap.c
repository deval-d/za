#include "helpers.h"
#include "l1_kernels.h"

#include <string.h>

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 319, 320, 321, 379, 380, 384, 385, 423, 424, 448, 449, 471, 472, 513, 1023, 2048}

static void sswap_ref(float *x, float *y, uint64_t n)
{
    for (uint64_t i = 0; i < n; ++i) {
        float tmp = x[i];
        x[i] = y[i];
        y[i] = tmp;
    }
}

static int check(const char *name, const float *xref, const float *yref,
                 const float *x, const float *y, uint64_t n)
{
    if (compare_vec_float(xref, x, n) || compare_vec_float(yref, y, n)) {
        fprintf(stderr, "%s failed for n=%llu\n", name, (unsigned long long)n);
        return 1;
    }
    return 0;
}

int main(void)
{
    const uint64_t sizes[] = SIZES;
    int failed = 0;

    srand(1);
    for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
        uint64_t n = sizes[s];
        float *x0 = random_vec_float(n);
        float *y0 = random_vec_float(n);
        float *xasm = malloc(n * sizeof(*xasm));
        float *yasm = malloc(n * sizeof(*yasm));
        float *xneon = malloc(n * sizeof(*xneon));
        float *yneon = malloc(n * sizeof(*yneon));
        float *xsme = malloc(n * sizeof(*xsme));
        float *ysme = malloc(n * sizeof(*ysme));
        float *xref = malloc(n * sizeof(*xref));
        float *yref = malloc(n * sizeof(*yref));
        if (!x0 || !y0 || !xasm || !yasm || !xneon || !yneon ||
            !xsme || !ysme || !xref || !yref) {
            fprintf(stderr, "allocation failed for n=%llu\n", (unsigned long long)n);
            free(x0); free(y0); free(xasm); free(yasm); free(xneon); free(yneon);
            free(xsme); free(ysme); free(xref); free(yref);
            return 1;
        }

        memcpy(xasm, x0, n * sizeof(*x0));
        memcpy(yasm, y0, n * sizeof(*y0));
        memcpy(xneon, x0, n * sizeof(*x0));
        memcpy(yneon, y0, n * sizeof(*y0));
        memcpy(xsme, x0, n * sizeof(*x0));
        memcpy(ysme, y0, n * sizeof(*y0));
        memcpy(xref, x0, n * sizeof(*x0));
        memcpy(yref, y0, n * sizeof(*y0));

        sswap_ref(xref, yref, n);
        sswap_asm(xasm, yasm, n);
        sswap_neon(xneon, yneon, n);
        sswap_sme(xsme, ysme, n);

        failed |= check("ASM", xref, yref, xasm, yasm, n);
        failed |= check("NEON", xref, yref, xneon, yneon, n);
        failed |= check("SME", xref, yref, xsme, ysme, n);

        free(x0); free(y0); free(xasm); free(yasm); free(xneon); free(yneon);
        free(xsme); free(ysme); free(xref); free(yref);
    }

    if (!failed)
        puts("SSWAP tests passed");
    return failed;
}
