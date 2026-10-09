#ifndef L1_KERNELS_H
#define L1_KERNELS_H

#include <stdint.h>

void saxpy_asm(const float *x, float *y, uint64_t n, float alpha); 
void saxpy_neon(const float *x, float *y, uint64_t n, float alpha);
void saxpy_sme4xVGx4(const float *x, float *y, uint64_t n, float alpha);
void saxpy_sme8xVGx4(const float *x, float *y, uint64_t n, float alpha);

float sdot_asm(const float *x, const float *y, uint64_t n);
float sdot_neon(const float *x, const float *y, uint64_t n);
float sdot_sme4xVGx4(const float *x, const float *y, uint64_t n);

float sasum_asm(const float *x, uint64_t n);
float sasum_neon(const float *x, uint64_t n);
float sasum_sme4xVGx4(const float *x, uint64_t n);

void sscal_asm(float *x, uint64_t, float alpha);
void sscal_neon(float *x, uint64_t n, float alpha);
void sscal_sme4xVGx4(float *x, uint64_t n, float alpha);
void sscal_sme8xVGx4(float *x, uint64_t n, float alpha);

void scopy_asm(const float *x, float *y, uint64_t n);
void scopy_neon(const float *x, float *y, uint64_t n);
void scopy_sme(const float *x, float *y, uint64_t n);

void sswap_asm(float *x, float *y, uint64_t n);
void sswap_neon(float *x, float *y, uint64_t n);
void sswap_sme(float *x, float *y, uint64_t n);

uint32_t isamax(const float *x, uint64_t n);
uint32_t isamax_neon(const float *x, uint64_t n);

float snrm2(const float *x, uint64_t n);
float snrm2_neon(const float *x, uint64_t n);





#endif
