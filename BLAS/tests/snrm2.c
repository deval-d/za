#include "helpers.h"
#include "l1_kernels.h"

#define SIZES {1, 2, 4, 7, 15, 16, 17, 35, 37, 38, 513, 1023}

static float snrm2_ref(const float *x, uint64_t n)
{
    double sum = 0.0;
    for (uint64_t i = 0; i < n; ++i)
        sum += (double)x[i] * x[i];
    return (float)sqrt(sum);
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
            fprintf(stderr, "allocation failed for n=%llu\n", (unsigned long long)n);
            return 1;
        }

        float ref = snrm2_ref(x, n);
        float result = snrm2(x, n);
        float neon = snrm2_neon(x, n);
        if (compare_vec_float(&ref, &result, 1)) {
            fprintf(stderr, "ASM failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        if (compare_vec_float(&ref, &neon, 1)) {
            fprintf(stderr, "NEON failed for n=%llu\n", (unsigned long long)n);
            failed = 1;
        }
        free(x);
    }

    if (!failed)
        puts("SNRM2 tests passed");
    return failed;
}
