.text

.global _dnrm2 
.p2align 4 

_dnrm2: 
    b    _dnrm2_neon


.global _dnrm2_neon
.p2align 4

_dnrm2_neon:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    mov     x8, x0

    movi    v0.2d, #0
    movi    v1.2d, #0
    movi    v2.2d, #0
    movi    v3.2d, #0

    cbz     w2, .Lneon_max_2

.Lneon_max_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fabs    v16.2d, v16.2d
    fabs    v17.2d, v17.2d
    fabs    v18.2d, v18.2d
    fabs    v19.2d, v19.2d

    fmax    v0.2d, v0.2d, v16.2d
    fmax    v1.2d, v1.2d, v17.2d
    fmax    v2.2d, v2.2d, v18.2d
    fmax    v3.2d, v3.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_max_8_loop

.Lneon_max_2:
    cbz     w3, .Lneon_max_reduce

.Lneon_max_2_loop:
    ldr     q16, [x8], #16
    fabs    v16.2d, v16.2d
    fmax    v0.2d, v0.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_max_2_loop

.Lneon_max_reduce:
    fmax    v0.2d, v0.2d, v1.2d
    fmax    v2.2d, v2.2d, v3.2d
    fmax    v0.2d, v0.2d, v2.2d
    fmaxp   d0, v0.2d

    cbz     w4, .Lneon_scale

.Lneon_max_scalar_loop:
    ldr     d16, [x8], #8
    fabs    d16, d16
    fmax    d0, d0, d16

    subs    w4, w4, #1
    b.ne    .Lneon_max_scalar_loop

.Lneon_scale:
    fcmp    d0, #0.0
    b.eq    .Lneon_done
    fcmp    d0, d0
    b.vs    .Lneon_done

    fmov    x6, d0
    mov     x7, #0x7ff0000000000000
    cmp     x6, x7
    b.eq    .Lneon_done

    lsr     x7, x6, #52
    and     x7, x7, #0x7ff
    cmp     x7, #2045
    b.hs    .Lneon_divide_scale
    cbz     x7, .Lneon_divide_scale

    fmov    d1, #1.0
    fdiv    d1, d1, d0
    dup     v1.2d, v1.d[0]
    mov     w6, #0
    b       .Lneon_sum_setup

.Lneon_divide_scale:
    dup     v1.2d, v0.d[0]
    mov     w6, #1

.Lneon_sum_setup:
    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    mov     x8, x0

    movi    v2.2d, #0
    movi    v3.2d, #0
    movi    v4.2d, #0
    movi    v5.2d, #0

    cbnz    w6, .Lneon_divide_8
    cbz     w2, .Lneon_sum_2

.Lneon_sum_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fmul    v16.2d, v16.2d, v1.2d
    fmul    v17.2d, v17.2d, v1.2d
    fmul    v18.2d, v18.2d, v1.2d
    fmul    v19.2d, v19.2d, v1.2d

    fmla    v2.2d, v16.2d, v16.2d
    fmla    v3.2d, v17.2d, v17.2d
    fmla    v4.2d, v18.2d, v18.2d
    fmla    v5.2d, v19.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_sum_8_loop
    b       .Lneon_sum_2

.Lneon_divide_8:
    cbz     w2, .Lneon_divide_2

.Lneon_divide_8_loop:
    ldp     q16, q17, [x8], #32
    ldp     q18, q19, [x8], #32

    fdiv    v16.2d, v16.2d, v1.2d
    fdiv    v17.2d, v17.2d, v1.2d
    fdiv    v18.2d, v18.2d, v1.2d
    fdiv    v19.2d, v19.2d, v1.2d

    fmla    v2.2d, v16.2d, v16.2d
    fmla    v3.2d, v17.2d, v17.2d
    fmla    v4.2d, v18.2d, v18.2d
    fmla    v5.2d, v19.2d, v19.2d

    subs    w2, w2, #1
    b.ne    .Lneon_divide_8_loop

.Lneon_divide_2:
    cbz     w3, .Lneon_sum_reduce

.Lneon_divide_2_loop:
    ldr     q16, [x8], #16
    fdiv    v16.2d, v16.2d, v1.2d
    fmla    v2.2d, v16.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_divide_2_loop
    b       .Lneon_sum_reduce

.Lneon_sum_2:
    cbz     w3, .Lneon_sum_reduce

.Lneon_sum_2_loop:
    ldr     q16, [x8], #16
    fmul    v16.2d, v16.2d, v1.2d
    fmla    v2.2d, v16.2d, v16.2d

    subs    w3, w3, #1
    b.ne    .Lneon_sum_2_loop

.Lneon_sum_reduce:
    fadd    v2.2d, v2.2d, v3.2d
    fadd    v4.2d, v4.2d, v5.2d
    fadd    v2.2d, v2.2d, v4.2d
    faddp   d2, v2.2d

    cbz     w4, .Lneon_sqrt
    cbnz    w6, .Lneon_scalar_divide_loop

.Lneon_scalar_loop:
    ldr     d16, [x8], #8
    fmul    d16, d16, d1
    fmadd   d2, d16, d16, d2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_loop
    b       .Lneon_sqrt

.Lneon_scalar_divide_loop:
    ldr     d16, [x8], #8
    fdiv    d16, d16, d1
    fmadd   d2, d16, d16, d2

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_divide_loop

.Lneon_sqrt:
    fsqrt   d2, d2
    fmul    d0, d0, d2

.Lneon_done:
    ret


.global _dnrm2_sve
.p2align 4

_dnrm2_sve:
    mov     w1, w1
    cbz     w1, .Lsve_empty

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm

    mov     x2, #0
    dup     z0.d, #0

    whilelo p0.d, x2, x1

.Lsve_max_loop:
    ld1d    z1.d, p0/z, [x0, x2, lsl #3]
    fabs    z1.d, p0/m, z1.d
    fmax    z0.d, p0/m, z0.d, z1.d

    incd    x2

    whilelo p0.d, x2, x1
    b.first .Lsve_max_loop

    ptrue   p1.d
    fmaxv   d0, p1, z0.d

    fcmp    d0, #0.0
    b.eq    .Lsve_done
    fcmp    d0, d0
    b.vs    .Lsve_done

    fmov    x3, d0
    mov     x4, #0x7ff0000000000000
    cmp     x3, x4
    b.eq    .Lsve_done

    mov     x2, #0
    dup     z2.d, #0
    dup     z3.d, z0.d[0]

    whilelo p0.d, x2, x1

.Lsve_sum_loop:
    ld1d    z1.d, p0/z, [x0, x2, lsl #3]
    fdiv    z1.d, p0/m, z1.d, z3.d
    fmla    z2.d, p0/m, z1.d, z1.d

    incd    x2

    whilelo p0.d, x2, x1
    b.first .Lsve_sum_loop

    faddv   d2, p1, z2.d
    fsqrt   d2, d2
    fmul    d0, d0, d2

.Lsve_done:
    fmov    x3, d0
    smstop sm
    fmov    d0, x3

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16
    ret

.Lsve_empty:
    fmov    d0, xzr
    ret
