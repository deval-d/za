.text

.global _sswap_asm
.p2align 4

_sswap_asm:
    cmp     x2, #320
    b.lo    _sswap_neon
    b.eq    _sswap_sme

    cmp     x2, #380
    b.lo    _sswap_neon
    cmp     x2, #384
    b.ls    _sswap_sme

    cmp     x2, #424
    b.lo    _sswap_neon
    cmp     x2, #448
    b.ls    _sswap_sme

    cmp     x2, #472
    b.lo    _sswap_neon
    b       _sswap_sme


.global _sswap_neon
.p2align 4

_sswap_neon:
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

    ldp     q16, q17, [x1], #32
    ldp     q18, q19, [x1], #32
    ldp     q20, q21, [x1], #32
    ldp     q22, q23, [x1], #32

    sub     x0, x0, #128
    sub     x1, x1, #128

    stp     q16, q17, [x0], #32
    stp     q18, q19, [x0], #32
    stp     q20, q21, [x0], #32
    stp     q22, q23, [x0], #32

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
    ldp     q16, q17, [x1], #32
    ldp     q18, q19, [x1], #32

    sub     x0, x0, #64
    sub     x1, x1, #64

    stp     q16, q17, [x0], #32
    stp     q18, q19, [x0], #32
    stp     q0, q1, [x1], #32
    stp     q2, q3, [x1], #32

    subs    x4, x4, #1
    b.ne    .Lsimd_16_loop

.Lsimd_4:
    cbz     x5, .Lscalar

.Lsimd_4_loop:
    ldr     q0, [x0]
    ldr     q16, [x1]
    str     q16, [x0], #16
    str     q0, [x1], #16

    subs    x5, x5, #1
    b.ne    .Lsimd_4_loop

.Lscalar:
    cbz     x6, .Lneon_return

.Lscalar_loop:
    ldr     s0, [x0]
    ldr     s16, [x1]
    str     s16, [x0], #4
    str     s0, [x1], #4

    subs    x6, x6, #1
    b.ne    .Lscalar_loop

.Lneon_return:
    ret


.global _sswap_sme
.p2align 4

_sswap_sme:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    cntw    x3          // number of floats in SVL
    lsl     x4, x3, #4  // number of floats in 4xVGx4
    lsl     x5, x3, #2  // number of floats in VGx4

    mov     x7, #0

    udiv    x6, x2, x4  // number of full 4xVGx4 chunks
    cbz     x6, .L4xVGx4_predicated

    ptrue   pn8.s

.L4xVGx4_full:
    add     x8, x7, x5
    add     x9, x7, x5, lsl #1
    add     x10, x8, x5, lsl #1

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x10, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x7, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x8, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x9, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x10, lsl #2]

    st1w    {z16.s-z19.s}, pn8, [x0, x7, lsl #2]
    st1w    {z20.s-z23.s}, pn8, [x0, x8, lsl #2]
    st1w    {z24.s-z27.s}, pn8, [x0, x9, lsl #2]
    st1w    {z28.s-z31.s}, pn8, [x0, x10, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x7, lsl #2]
    st1w    {z4.s-z7.s}, pn8, [x1, x8, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x9, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x10, lsl #2]

    add     x7, x7, x4
    subs    x6, x6, #1
    b.ne    .L4xVGx4_full

.L4xVGx4_predicated:
    add     x8, x7, x5
    add     x9, x7, x5, lsl #1
    add     x10, x8, x5, lsl #1

    whilelo pn8.s, x7, x2, vlx4
    b.none  .L4xVGx4_return

    whilelo pn9.s, x8, x2, vlx4
    whilelo pn10.s, x9, x2, vlx4
    whilelo pn11.s, x10, x2, vlx4

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z4.s-z7.s}, pn9/z, [x0, x8, lsl #2]
    ld1w    {z8.s-z11.s}, pn10/z, [x0, x9, lsl #2]
    ld1w    {z12.s-z15.s}, pn11/z, [x0, x10, lsl #2]

    ld1w    {z16.s-z19.s}, pn8/z, [x1, x7, lsl #2]
    ld1w    {z20.s-z23.s}, pn9/z, [x1, x8, lsl #2]
    ld1w    {z24.s-z27.s}, pn10/z, [x1, x9, lsl #2]
    ld1w    {z28.s-z31.s}, pn11/z, [x1, x10, lsl #2]

    st1w    {z16.s-z19.s}, pn8, [x0, x7, lsl #2]
    st1w    {z20.s-z23.s}, pn9, [x0, x8, lsl #2]
    st1w    {z24.s-z27.s}, pn10, [x0, x9, lsl #2]
    st1w    {z28.s-z31.s}, pn11, [x0, x10, lsl #2]

    st1w    {z0.s-z3.s}, pn8, [x1, x7, lsl #2]
    st1w    {z4.s-z7.s}, pn9, [x1, x8, lsl #2]
    st1w    {z8.s-z11.s}, pn10, [x1, x9, lsl #2]
    st1w    {z12.s-z15.s}, pn11, [x1, x10, lsl #2]

.L4xVGx4_return:
    smstop sm

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
