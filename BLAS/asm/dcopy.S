.text

.global _dcopy
.p2align 4

_dcopy:
    cmp     w2, #308
    b.lo    _dcopy_neon
    b       _dcopy_sme


.global _dcopy_neon
.p2align 4

_dcopy_neon:
    cbz     w2, .Lneon_done

    lsr     w3, w2, #4
    and     w4, w2, #15
    lsr     w4, w4, #3
    and     w5, w2, #7
    lsr     w5, w5, #1
    and     w6, w2, #1

    cbz     w3, .Lsimd_8

.Lsimd_16_loop:
    ldp     q0, q1, [x0], #32
    ldp     q2, q3, [x0], #32
    ldp     q4, q5, [x0], #32
    ldp     q6, q7, [x0], #32

    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32
    stp     q4, q5, [x1], #32
    stp     q6, q7, [x1], #32

    subs    w3, w3, #1
    b.ne    .Lsimd_16_loop

.Lsimd_8:
    cbz     w4, .Lsimd_2

.Lsimd_8_loop:
    ldp     q0, q1, [x0], #32
    ldp     q2, q3, [x0], #32

    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32

    subs    w4, w4, #1
    b.ne    .Lsimd_8_loop

.Lsimd_2:
    cbz     w5, .Lscalar

.Lsimd_2_loop:
    ldr     q0, [x0], #16
    str     q0, [x1], #16

    subs    w5, w5, #1
    b.ne    .Lsimd_2_loop

.Lscalar:
    cbz     w6, .Lneon_done
    ldr     d0, [x0]
    str     d0, [x1]

.Lneon_done:
    ret


.global _dcopy_sve
.p2align 4

_dcopy_sve:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    mov     x4, #0
    whilelo p0.d, x4, x2
    b.none  .Lsve_done

.Lsve_loop:
    ld1d    z0.d, p0/z, [x0, x4, lsl #3]
    st1d    z0.d, p0, [x1, x4, lsl #3]

    incd    x4
    whilelo p0.d, x4, x2
    b.first .Lsve_loop

.Lsve_done:
    smstop  sm

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret


.global _dcopy_sme
.p2align 4

_dcopy_sme:
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
    cbz     x6, .Lsme_tail_loop

    ptrue   pn8.d

.Lsme_full_loop:
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

    st1d    {z0.d-z3.d}, pn8, [x1, x3, lsl #3]
    st1d    {z4.d-z7.d}, pn8, [x1, x7, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x8, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x9, lsl #3]

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x10, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x11, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x12, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x13, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x10, lsl #3]
    st1d    {z4.d-z7.d}, pn8, [x1, x11, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x12, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x13, lsl #3]

    add     x3, x3, x5
    subs    x6, x6, #1
    b.ne    .Lsme_full_loop

.Lsme_tail_loop:
    add     x7, x3, x4, lsl #2
    add     x8, x7, x4, lsl #2
    add     x9, x8, x4, lsl #2

    whilelo pn8.d, x3, x2, vlx4
    b.none  .Lsme_done

    whilelo pn9.d, x7, x2, vlx4
    whilelo pn10.d, x8, x2, vlx4
    whilelo pn11.d, x9, x2, vlx4

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x3, lsl #3]
    ld1d    {z4.d-z7.d}, pn9/z, [x0, x7, lsl #3]
    ld1d    {z8.d-z11.d}, pn10/z, [x0, x8, lsl #3]
    ld1d    {z12.d-z15.d}, pn11/z, [x0, x9, lsl #3]

    st1d    {z0.d-z3.d}, pn8, [x1, x3, lsl #3]
    st1d    {z4.d-z7.d}, pn9, [x1, x7, lsl #3]
    st1d    {z8.d-z11.d}, pn10, [x1, x8, lsl #3]
    st1d    {z12.d-z15.d}, pn11, [x1, x9, lsl #3]

    add     x3, x3, x4, lsl #4
    b       .Lsme_tail_loop

.Lsme_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret
