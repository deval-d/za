#include "helpers.h"
#include "l1_kernels.h"

#define SIZES {1, 2, 4, 7, 15, 16, 17, 35, 37, 38, 513, 1023}

static uint32_t isamax_ref(const float *x, uint64_t n)
{
    uint32_t index = 0;
    for (uint64_t i = 1; i < n; ++i)
        if (fabsf(x[i]) > fabsf(x[index]))
            index = (uint32_t)i;
    return index;
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

        uint32_t ref = isamax_ref(x, n);
        uint32_t result = isamax(x, n);
        uint32_t neon = isamax_neon(x, n);
        if (result != ref) {
            fprintf(stderr, "ASM failed for n=%llu: expected %u, got %u\n",
                    (unsigned long long)n, ref, result);
            failed = 1;
        }
        if (neon != ref) {
            fprintf(stderr, "NEON failed for n=%llu: expected %u, got %u\n",
                    (unsigned long long)n, ref, neon);
            failed = 1;
        }
        free(x);
    }

    if (!failed)
        puts("ISAMAX tests passed");
    return failed;
}
