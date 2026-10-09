#include "helpers.h"
#include "l1_kernels.h"

#define SIZES {1, 2, 4, 7, 15, 35, 37, 38, 513, 1023}

static float sasum_ref(const float *x, uint64_t n)
{
    float result = 0.0f;
    for (uint64_t i = 0; i < n; ++i)
        result += fabsf(x[i]);
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
        if (!x) {
            fprintf(stderr, "allocation failed for n=%llu\n",
                    (unsigned long long)n);
            return 1;
        }

        float ref = sasum_ref(x, n);
        float neon = sasum_neon(x, n);
        float sme4xVGx4 = sasum_sme4xVGx4(x, n);

        if (compare_vec_float(&ref, &neon, 1)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(&ref, &sme4xVGx4, 1)) {
            fprintf(stderr, "SME 4xVGx4 failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }

        free(x);
    }

    if (!failed)
        puts("SASUM tests passed");
    return failed;
}
