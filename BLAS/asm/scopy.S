.text

.global _scopy_asm
.p2align 4

_scopy_asm:
    cmp     x2, #496
    b.lo    _scopy_neon
    b       _scopy_sme


.global _scopy_neon
.p2align 4

_scopy_neon:
    lsr     x3, x2, #5
    and     x4, x2, #31
    lsr     x4, x4, #4
    and     x5, x2, #15
    lsr     x5, x5, #2
    and     x6, x2, #3

    cbz     x3, .Lsimd_16

.Lsimd_32_loop:
    ldp     q0, q1, [x0], #32
    ldp     q2, q3, [x0], #32
    ldp     q4, q5, [x0], #32
    ldp     q6, q7, [x0], #32

    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32
    stp     q4, q5, [x1], #32
    stp     q6, q7, [x1], #32

    subs    x3, x3, #1
    b.ne    .Lsimd_32_loop

.Lsimd_16:
    cbz     x4, .Lsimd_4

.Lsimd_16_loop:
    ldp     q0, q1, [x0], #32
    ldp     q2, q3, [x0], #32

    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32

    subs    x4, x4, #1
    b.ne    .Lsimd_16_loop

.Lsimd_4:
    cbz     x5, .Lscalar

.Lsimd_4_loop:
    ldr     q0, [x0], #16
    str     q0, [x1], #16

    subs    x5, x5, #1
    b.ne    .Lsimd_4_loop

.Lscalar:
    cbz     x6, .Lneon_return

.Lscalar_loop:
    ldr     s0, [x0], #4
    str     s0, [x1], #4

    subs    x6, x6, #1
    b.ne    .Lscalar_loop

.Lneon_return:
    ret


.global _scopy_sme
.p2align 4

_scopy_sme:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    cntw    x3          // number of floats in SVL
    lsl     x4, x3, #5  // number of floats in 8xVGx4
    lsl     x5, x3, #2  // number of floats in VGx4

    mov     x7, #0

    udiv    x6, x2, x4  // number of full 8xVGx4 chunks
    cbz     x6, .L8xVGx4_predicated

    ptrue   pn8.s

.L8xVGx4_full:
    add     x8, x7, x5
    add     x9, x7, x5, lsl #1
    add     x10, x8, x5, lsl #1
    add     x11, x7, x5, lsl #2
    add     x12, x8, x5, lsl #2
    add     x13, x9, x5, lsl #2
    add     x14, x10, x5, lsl #2

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x0, x13, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x0, x14, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x7, lsl #2]
    st1w    {z4.s-z7.s}, pn8, [x1, x8, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x9, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x10, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x1, x11, lsl #2]
    st1w    {z20.s-z23.s}, pn8, [x1, x12, lsl #2]
    st1w    {z24.s-z27.s}, pn8, [x1, x13, lsl #2]
    st1w    {z28.s-z31.s}, pn8, [x1, x14, lsl #2]

    add     x7, x7, x4
    subs    x6, x6, #1
    b.ne    .L8xVGx4_full

.L8xVGx4_predicated:
    add     x8, x7, x5
    add     x9, x7, x5, lsl #1
    add     x10, x8, x5, lsl #1
    add     x11, x7, x5, lsl #2
    add     x12, x8, x5, lsl #2
    add     x13, x9, x5, lsl #2
    add     x14, x10, x5, lsl #2

    whilelo pn8.s, x7, x2, vlx4
    b.none  .L8xVGx4_return

    whilelo pn9.s, x8, x2, vlx4
    whilelo pn10.s, x9, x2, vlx4
    whilelo pn11.s, x10, x2, vlx4
    whilelo pn12.s, x11, x2, vlx4
    whilelo pn13.s, x12, x2, vlx4
    whilelo pn14.s, x13, x2, vlx4
    whilelo pn15.s, x14, x2, vlx4

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z4.s-z7.s}, pn9/z, [x0, x8, lsl #2]
    ld1w    {z8.s-z11.s}, pn10/z, [x0, x9, lsl #2]
    ld1w    {z12.s-z15.s}, pn11/z, [x0, x10, lsl #2]
    ld1w    {z16.s-z19.s}, pn12/z, [x0, x11, lsl #2]
    ld1w    {z20.s-z23.s}, pn13/z, [x0, x12, lsl #2]
    ld1w    {z24.s-z27.s}, pn14/z, [x0, x13, lsl #2]
    ld1w    {z28.s-z31.s}, pn15/z, [x0, x14, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x7, lsl #2]
    st1w    {z4.s-z7.s}, pn9, [x1, x8, lsl #2]
    st1w    {z8.s-z11.s}, pn10, [x1, x9, lsl #2]
    st1w    {z12.s-z15.s}, pn11, [x1, x10, lsl #2]
    st1w    {z16.s-z19.s}, pn12, [x1, x11, lsl #2]
    st1w    {z20.s-z23.s}, pn13, [x1, x12, lsl #2]
    st1w    {z24.s-z27.s}, pn14, [x1, x13, lsl #2]
    st1w    {z28.s-z31.s}, pn15, [x1, x14, lsl #2]

.L8xVGx4_return:
    smstop sm

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
