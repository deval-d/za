.text

.global _dswap
.p2align 4

_dswap:
    cmp     x2, #160
    b.lo    _dswap_neon
    b.eq    _dswap_sme

    cmp     x2, #190
    b.lo    _dswap_neon
    cmp     x2, #192
    b.ls    _dswap_sme

    cmp     x2, #212
    b.lo    _dswap_neon
    cmp     x2, #224
    b.ls    _dswap_sme

    cmp     x2, #236
    b.lo    _dswap_neon
    b       _dswap_sme


.global _dswap_neon
.p2align 4

_dswap_neon:
    cbz     x2, .Lneon_done

    lsr     x3, x2, #3
    and     x4, x2, #7
    lsr     x4, x4, #1
    and     x5, x2, #1

    cbz     x3, .Lsimd_2

.Lsimd_8_loop:
    ldp     q0, q1, [x0]
    ldp     q2, q3, [x0, #32]
    ldp     q4, q5, [x1]
    ldp     q6, q7, [x1, #32]

    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32
    stp     q4, q5, [x0], #32
    stp     q6, q7, [x0], #32

    subs    x3, x3, #1
    b.ne    .Lsimd_8_loop

.Lsimd_2:
    cbz     x4, .Lscalar

.Lsimd_2_loop:
    ldr     q0, [x0]
    ldr     q1, [x1]
    str     q0, [x1], #16
    str     q1, [x0], #16

    subs    x4, x4, #1
    b.ne    .Lsimd_2_loop

.Lscalar:
    cbz     x5, .Lneon_done
    ldr     d0, [x0]
    ldr     d1, [x1]
    str     d0, [x1]
    str     d1, [x0]

.Lneon_done:
    ret


.global _dswap_sve
.p2align 4

_dswap_sve:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    mov     x3, #0
    whilelo p0.d, x3, x2
    b.none  .Lsve_done

.Lsve_loop:
    ld1d    z0.d, p0/z, [x0, x3, lsl #3]
    ld1d    z1.d, p0/z, [x1, x3, lsl #3]
    st1d    z0.d, p0, [x1, x3, lsl #3]
    st1d    z1.d, p0, [x0, x3, lsl #3]

    incd    x3
    whilelo p0.d, x3, x2
    b.first .Lsve_loop

.Lsve_done:
    smstop  sm

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret


.global _dswap_sme
.p2align 4

_dswap_sme:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart

    mov     x3, #0
    cntd    x4

    lsl     x5, x4, #5
    udiv    x6, x2, x5
    ptrue   pn8.d

    cbz     x6, .Lsme4_full

.Lsme8_full:
    add     x7, x3, x4, lsl #2
    add     x8, x7, x4, lsl #2
    add     x9, x8, x4, lsl #2
    add     x10, x9, x4, lsl #2
    add     x11, x10, x4, lsl #2
    add     x12, x11, x4, lsl #2
    add     x13, x12, x4, lsl #2

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x3, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x7, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x8, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x9, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x3, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x7, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x8, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x9, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x3, lsl #3]
    st1d    {z4.d-z7.d}, pn8, [x1, x7, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x8, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x9, lsl #3]

    st1d    {z16.d-z19.d}, pn8, [x0, x3, lsl #3]
    st1d    {z20.d-z23.d}, pn8, [x0, x7, lsl #3]
    st1d    {z24.d-z27.d}, pn8, [x0, x8, lsl #3]
    st1d    {z28.d-z31.d}, pn8, [x0, x9, lsl #3]

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x10, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x11, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x12, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x13, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x10, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x11, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x12, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x13, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x10, lsl #3]
    st1d    {z4.d-z7.d}, pn8, [x1, x11, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x12, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x13, lsl #3]

    st1d    {z16.d-z19.d}, pn8, [x0, x10, lsl #3]
    st1d    {z20.d-z23.d}, pn8, [x0, x11, lsl #3]
    st1d    {z24.d-z27.d}, pn8, [x0, x12, lsl #3]
    st1d    {z28.d-z31.d}, pn8, [x0, x13, lsl #3]

    add     x3, x3, x5
    subs    x6, x6, #1
    b.ne    .Lsme8_full

.Lsme4_full:
    sub     x6, x2, x3
    lsl     x5, x4, #4
    cmp     x6, x5
    b.lo    .Lsme_tail

    add     x7, x3, x4, lsl #2
    add     x8, x7, x4, lsl #2
    add     x9, x8, x4, lsl #2

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x3, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x7, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x8, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x9, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x3, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x7, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x8, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x9, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x3, lsl #3]
    st1d    {z4.d-z7.d}, pn8, [x1, x7, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x8, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x9, lsl #3]

    st1d    {z16.d-z19.d}, pn8, [x0, x3, lsl #3]
    st1d    {z20.d-z23.d}, pn8, [x0, x7, lsl #3]
    st1d    {z24.d-z27.d}, pn8, [x0, x8, lsl #3]
    st1d    {z28.d-z31.d}, pn8, [x0, x9, lsl #3]

    add     x3, x3, x5

.Lsme_tail:
    whilelo pn8.d, x3, x2, vlx4
    b.none  .Lsme_done

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x3, lsl #3]
    ld1d    {z16.d-z19.d}, pn8/z, [x1, x3, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x3, lsl #3]
    st1d    {z16.d-z19.d}, pn8, [x0, x3, lsl #3]

    add     x3, x3, x4, lsl #2
    b       .Lsme_tail

.Lsme_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret
