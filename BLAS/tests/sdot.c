#include "helpers.h"
#include "l1_kernels.h"

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 513, 1023}

static float sdot_ref(const float *x, const float *y, uint64_t n)
{
    float result = 0.0f;
    for (uint64_t i = 0; i < n; ++i)
        result = fmaf(x[i], y[i], result);
    return result;
}

int main(void)
{
    const uint64_t sizes[] = SIZES;
    int failed = 0;

    srand(1);
    for (size_t s = 0; s < sizeof(sizes) / sizeof(sizes[0]); ++s) {
        uint64_t n = sizes[s];
        float *x = random_vec_float(n);
        float *y = random_vec_float(n);
        if (!x || !y) {
            fprintf(stderr, "allocation failed for n=%llu\n",
                    (unsigned long long)n);
            free(x);
            free(y);
            return 1;
        }

        float ref = sdot_ref(x, y, n);
        float neon = sdot_neon(x, y, n);
        float sme4xVGx4 = sdot_sme4xVGx4(x, y, n);

        if (compare_vec_float(&ref, &neon, 1)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(&ref, &sme4xVGx4, 1)) {
            fprintf(stderr, "SME 4xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }

        free(x);
        free(y);
    }

    if (!failed)
        puts("SDOT tests passed");
    return failed;
}
