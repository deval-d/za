.text

.global _sgemv
.p2align 4

_sgemv:
    cmp     x3, #16
    b.ls    _sgemv_neon

    mul     x5, x3, x4
    cmp     x5, #1536
    b.ls    _sgemv_neon

    cmp     x3, #32
    b.hi    _sgemv_sme
    cmp     x4, #64
    b.ls    _sgemv_neon
    b       _sgemv_sme


.global _sgemv_neon
.p2align 4

_sgemv_neon:
    cmp     x3, #16
    b.ls    _sgemv_neon_i_outer

    mul     x5, x3, x4
    cmp     x5, #2048
    b.ls    _sgemv_neon_i_outer

    cmp     x3, #32
    b.hi    _sgemv_neon_j_outer
    cmp     x4, #128
    b.ls    _sgemv_neon_i_outer
    b       _sgemv_neon_j_outer


.global _sgemv_neon_i_outer
.p2align 4

_sgemv_neon_i_outer:
    mov     x5, #0
    cmp     x3, #16
    b.lo    .Li_rows4

.Li_rows16_loop:
    add     x9, x2, x5, lsl #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

    mov     x6, #0

.Li_16x4_loop:
    add     x8, x6, #4
    cmp     x8, x4
    b.hi    .Li_16x1

    add     x10, x1, x6, lsl #2
    ldr     q20, [x10]
    fmul    v20.4s, v20.4s, v0.s[0]

    madd    x7, x6, x3, x5
    add     x10, x0, x7, lsl #2

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[1]
    fmla    v17.4s, v22.4s, v20.s[1]
    fmla    v18.4s, v23.4s, v20.s[1]
    fmla    v19.4s, v24.4s, v20.s[1]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[2]
    fmla    v17.4s, v22.4s, v20.s[2]
    fmla    v18.4s, v23.4s, v20.s[2]
    fmla    v19.4s, v24.4s, v20.s[2]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[3]
    fmla    v17.4s, v22.4s, v20.s[3]
    fmla    v18.4s, v23.4s, v20.s[3]
    fmla    v19.4s, v24.4s, v20.s[3]

    mov     x6, x8
    b       .Li_16x4_loop

.Li_16x1:
    cmp     x6, x4
    b.hs    .Li_16_store

.Li_16x1_loop:
    add     x10, x1, x6, lsl #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    x7, x6, x3, x5
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     x6, x6, #1
    cmp     x6, x4
    b.lo    .Li_16x1_loop

.Li_16_store:
    add     x9, x2, x5, lsl #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     x5, x5, #16
    sub     x7, x3, x5
    cmp     x7, #16
    b.hs    .Li_rows16_loop

.Li_rows4:
    sub     x7, x3, x5
    cmp     x7, #4
    b.lo    .Li_scalar

.Li_rows4_loop:
    add     x9, x2, x5, lsl #2
    ldr     q16, [x9]
    fmul    v16.4s, v16.4s, v1.s[0]

    mov     x6, #0

.Li_4x4_loop:
    add     x8, x6, #4
    cmp     x8, x4
    b.hi    .Li_4x1

    add     x10, x1, x6, lsl #2
    ldr     q20, [x10]
    fmul    v20.4s, v20.4s, v0.s[0]

    madd    x7, x6, x3, x5
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[1]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[2]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[3]

    mov     x6, x8
    b       .Li_4x4_loop

.Li_4x1:
    cmp     x6, x4
    b.hs    .Li_4_store

.Li_4x1_loop:
    add     x10, x1, x6, lsl #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    x7, x6, x3, x5
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     x6, x6, #1
    cmp     x6, x4
    b.lo    .Li_4x1_loop

.Li_4_store:
    add     x9, x2, x5, lsl #2
    str     q16, [x9]

    add     x5, x5, #4
    sub     x7, x3, x5
    cmp     x7, #4
    b.hs    .Li_rows4_loop

.Li_scalar:
    cmp     x5, x3
    b.hs    .Li_done

.Li_scalar_row_loop:
    add     x9, x2, x5, lsl #2
    ldr     s16, [x9]
    fmul    s16, s16, s1

    mov     x6, #0
    cbz     x4, .Li_scalar_store

.Li_scalar_col_loop:
    add     x10, x1, x6, lsl #2
    ldr     s20, [x10]
    fmul    s20, s20, s0

    madd    x7, x6, x3, x5
    add     x10, x0, x7, lsl #2
    ldr     s21, [x10]
    fmadd   s16, s21, s20, s16

    add     x6, x6, #1
    cmp     x6, x4
    b.lo    .Li_scalar_col_loop

.Li_scalar_store:
    str     s16, [x9]
    add     x5, x5, #1
    cmp     x5, x3
    b.lo    .Li_scalar_row_loop

.Li_done:
    ret


.global _sgemv_neon_j_outer
.p2align 4

_sgemv_neon_j_outer:
    mov     x5, #0
    cmp     x4, #4
    b.lo    .Lj_cols1

.Lj_cols4_loop:
    add     x9, x1, x5, lsl #2
    ldr     q20, [x9]
    fmul    v20.4s, v20.4s, v0.s[0]

    mov     x6, #0
    cmp     x3, #16
    b.lo    .Lj_4_rows4

.Lj_4_rows16_loop:
    add     x9, x2, x6, lsl #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    x5, .Lj_4_rows16_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

.Lj_4_rows16_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[1]
    fmla    v17.4s, v22.4s, v20.s[1]
    fmla    v18.4s, v23.4s, v20.s[1]
    fmla    v19.4s, v24.4s, v20.s[1]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[2]
    fmla    v17.4s, v22.4s, v20.s[2]
    fmla    v18.4s, v23.4s, v20.s[2]
    fmla    v19.4s, v24.4s, v20.s[2]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.4s, v21.4s, v20.s[3]
    fmla    v17.4s, v22.4s, v20.s[3]
    fmla    v18.4s, v23.4s, v20.s[3]
    fmla    v19.4s, v24.4s, v20.s[3]

    add     x9, x2, x6, lsl #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     x6, x6, #16
    sub     x7, x3, x6
    cmp     x7, #16
    b.hs    .Lj_4_rows16_loop

.Lj_4_rows4:
    sub     x7, x3, x6
    cmp     x7, #4
    b.lo    .Lj_4_scalar

.Lj_4_rows4_loop:
    add     x9, x2, x6, lsl #2
    ldr     q16, [x9]

    cbnz    x5, .Lj_4_rows4_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]

.Lj_4_rows4_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[1]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[2]

    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[3]

    add     x9, x2, x6, lsl #2
    str     q16, [x9]

    add     x6, x6, #4
    sub     x7, x3, x6
    cmp     x7, #4
    b.hs    .Lj_4_rows4_loop

.Lj_4_scalar:
    cmp     x6, x3
    b.hs    .Lj_4_next

.Lj_4_scalar_loop:
    add     x9, x2, x6, lsl #2
    ldr     s16, [x9]

    cbnz    x5, .Lj_4_scalar_accumulate
    fmul    s16, s16, s1

.Lj_4_scalar_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2

    ldr     s21, [x10]
    fmla    s16, s21, v20.s[0]
    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[1]
    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[2]
    add     x7, x7, x3
    add     x10, x0, x7, lsl #2
    ldr     s21, [x10]
    fmla    s16, s21, v20.s[3]

    str     s16, [x9]
    add     x6, x6, #1
    cmp     x6, x3
    b.lo    .Lj_4_scalar_loop

.Lj_4_next:
    add     x5, x5, #4
    sub     x7, x4, x5
    cmp     x7, #4
    b.hs    .Lj_cols4_loop

.Lj_cols1:
    cmp     x5, x4
    b.hs    .Lj_done

.Lj_cols1_loop:
    add     x9, x1, x5, lsl #2
    ldr     s20, [x9]
    fmul    s20, s20, s0

    mov     x6, #0
    cmp     x3, #16
    b.lo    .Lj_1_rows4

.Lj_1_rows16_loop:
    add     x9, x2, x6, lsl #2
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    x5, .Lj_1_rows16_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]
    fmul    v17.4s, v17.4s, v1.s[0]
    fmul    v18.4s, v18.4s, v1.s[0]
    fmul    v19.4s, v19.4s, v1.s[0]

.Lj_1_rows16_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.4s, v21.4s, v20.s[0]
    fmla    v17.4s, v22.4s, v20.s[0]
    fmla    v18.4s, v23.4s, v20.s[0]
    fmla    v19.4s, v24.4s, v20.s[0]

    add     x9, x2, x6, lsl #2
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     x6, x6, #16
    sub     x7, x3, x6
    cmp     x7, #16
    b.hs    .Lj_1_rows16_loop

.Lj_1_rows4:
    sub     x7, x3, x6
    cmp     x7, #4
    b.lo    .Lj_1_scalar

.Lj_1_rows4_loop:
    add     x9, x2, x6, lsl #2
    ldr     q16, [x9]

    cbnz    x5, .Lj_1_rows4_accumulate
    fmul    v16.4s, v16.4s, v1.s[0]

.Lj_1_rows4_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2
    ldr     q21, [x10]
    fmla    v16.4s, v21.4s, v20.s[0]
    str     q16, [x9]

    add     x6, x6, #4
    sub     x7, x3, x6
    cmp     x7, #4
    b.hs    .Lj_1_rows4_loop

.Lj_1_scalar:
    cmp     x6, x3
    b.hs    .Lj_1_next

.Lj_1_scalar_loop:
    add     x9, x2, x6, lsl #2
    ldr     s16, [x9]

    cbnz    x5, .Lj_1_scalar_accumulate
    fmul    s16, s16, s1

.Lj_1_scalar_accumulate:
    madd    x7, x5, x3, x6
    add     x10, x0, x7, lsl #2
    ldr     s21, [x10]
    fmadd   s16, s21, s20, s16
    str     s16, [x9]

    add     x6, x6, #1
    cmp     x6, x3
    b.lo    .Lj_1_scalar_loop

.Lj_1_next:
    add     x5, x5, #1
    cmp     x5, x4
    b.lo    .Lj_cols1_loop

.Lj_done:
    ret


.global _sgemv_sme
.p2align 4

_sgemv_sme:
    rdsvl   x5, #1
    cmp     x5, #32
    b.lo    _sgemv_sme4xVGx4
    b       _sgemv_sme8xVGx4


.global _sgemv_sme8xVGx4
.p2align 4

/// alpha   s0
/// beta    s1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.s = dup alpha
//  z1.s = dup beta
//
//  x5 = cntw
//  x6 = columns remaining
//  x7 = i
//
//  w8 = first ZA group
//  w9 = second ZA group, spaced halfway across ZA
//
//  keep 8xVGx4 worth of A*x in ZA live, so 32 SVL's.
//
//  loop over i:
//      zero ZA
//      loop over j:
//          z3.s = dup x[j]
//          {z4.s-z7.s} = A[j * m + i .. j * m + i + 4 * x5]
//          za.s[w8, 0, vgx4] += {z4.s-z7.s} * z3.s
//          ...
//          za.s[w9, 3, vgx4] += {z16.s-z19.s} * z3.s
//      y[i .. i + 32 * x5] = z0.s * ZA + z1.s * y[i .. i + 32 * x5]
//
//  leftover rows:
//      keep 4xVGx4 or 1xVGx4 worth of A*x in ZA live.
_sgemv_sme8xVGx4:

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w5, s0
    fmov    w6, s1

    smstart
    ptrue   p0.s

    fmov    s0, w5
    dup     z0.s, z0.s[0]
    fmov    s1, w6
    dup     z1.s, z1.s[0]

    cntw    x5
    mov     x7, #0
    mov     w8, #0

    lsr     w9, w5, #1

    ptrue   pn8.s
    ptrue   pn9.s
    ptrue   pn10.s
    ptrue   pn11.s
    ptrue   pn12.s
    ptrue   pn13.s
    ptrue   pn14.s
    ptrue   pn15.s

.Lsme_8xVGx4_i_loop:
    cmp     x7, x3
    b.hs    .Lsme_8xVGx4_done

    sub     x10, x3, x7
    lsl     x11, x5, #2
    cmp     x10, x11
    b.ls    .Lsme_8xVGx4_1x_tail
    lsl     x11, x5, #4
    cmp     x10, x11
    b.ls    .Lsme_8xVGx4_4x_tail

    lsl     x11, x5, #5
    cmp     x10, x11
    b.hs    .Lsme_8xVGx4_load

    mov     x10, x7
    whilelo pn8.s, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn12.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn13.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn14.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn15.s, x10, x3, vlx4

.Lsme_8xVGx4_load:
    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #2
    lsl     x13, x3, #2

    cbz     x6, .Lsme_8xVGx4_store

.Lsme_8xVGx4_j_loop:
    ldr     s3, [x11], #4
    dup     z3.s, z3.s[0]

    ld1w    {z4.s-z7.s}, pn8/z, [x12]
    ld1w    {z8.s-z11.s}, pn9/z, [x12, #4, mul vl]
    ld1w    {z12.s-z15.s}, pn10/z, [x12, #8, mul vl]
    ld1w    {z16.s-z19.s}, pn11/z, [x12, #12, mul vl]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x10, x12, x5, lsl #6
    ld1w    {z4.s-z7.s}, pn12/z, [x10]
    ld1w    {z8.s-z11.s}, pn13/z, [x10, #4, mul vl]
    ld1w    {z12.s-z15.s}, pn14/z, [x10, #8, mul vl]
    ld1w    {z16.s-z19.s}, pn15/z, [x10, #12, mul vl]

    fmla    za.s[w9, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w9, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w9, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w9, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_j_loop

.Lsme_8xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    add     x10, x2, x7, lsl #2
    ld1w    {z20.s-z23.s}, pn8/z, [x10]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn8, [x10]

    mov     {z4.s-z7.s}, za.s[w8, 1, vgx4]
    ld1w    {z20.s-z23.s}, pn9/z, [x10, #4, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn9, [x10, #4, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 2, vgx4]
    ld1w    {z20.s-z23.s}, pn10/z, [x10, #8, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn10, [x10, #8, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 3, vgx4]
    ld1w    {z20.s-z23.s}, pn11/z, [x10, #12, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn11, [x10, #12, mul vl]

    add     x10, x10, x5, lsl #6

    mov     {z4.s-z7.s}, za.s[w9, 0, vgx4]
    ld1w    {z20.s-z23.s}, pn12/z, [x10]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn12, [x10]

    mov     {z4.s-z7.s}, za.s[w9, 1, vgx4]
    ld1w    {z20.s-z23.s}, pn13/z, [x10, #4, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn13, [x10, #4, mul vl]

    mov     {z4.s-z7.s}, za.s[w9, 2, vgx4]
    ld1w    {z20.s-z23.s}, pn14/z, [x10, #8, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn14, [x10, #8, mul vl]

    mov     {z4.s-z7.s}, za.s[w9, 3, vgx4]
    ld1w    {z20.s-z23.s}, pn15/z, [x10, #12, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn15, [x10, #12, mul vl]

    incw    x7, all, mul #16
    incw    x7, all, mul #16
    b       .Lsme_8xVGx4_i_loop

.Lsme_8xVGx4_4x_tail:
    mov     x10, x7
    whilelo pn8.s, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.s, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.s, x10, x3, vlx4

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #2
    lsl     x13, x3, #2

    cbz     x6, .Lsme_8xVGx4_4x_store

.Lsme_8xVGx4_4x_j_loop:
    ldr     s3, [x11], #4
    dup     z3.s, z3.s[0]

    ld1w    {z4.s-z7.s}, pn8/z, [x12]
    ld1w    {z8.s-z11.s}, pn9/z, [x12, #4, mul vl]
    ld1w    {z12.s-z15.s}, pn10/z, [x12, #8, mul vl]
    ld1w    {z16.s-z19.s}, pn11/z, [x12, #12, mul vl]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_4x_j_loop

.Lsme_8xVGx4_4x_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    add     x10, x2, x7, lsl #2
    ld1w    {z20.s-z23.s}, pn8/z, [x10]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn8, [x10]

    mov     {z4.s-z7.s}, za.s[w8, 1, vgx4]
    ld1w    {z20.s-z23.s}, pn9/z, [x10, #4, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn9, [x10, #4, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 2, vgx4]
    ld1w    {z20.s-z23.s}, pn10/z, [x10, #8, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn10, [x10, #8, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 3, vgx4]
    ld1w    {z20.s-z23.s}, pn11/z, [x10, #12, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn11, [x10, #12, mul vl]
    b       .Lsme_8xVGx4_done

.Lsme_8xVGx4_1x_tail:
    whilelo pn8.s, x7, x3, vlx4
    b.none  .Lsme_8xVGx4_done

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #2
    lsl     x13, x3, #2

    cbz     x6, .Lsme_8xVGx4_1x_store

.Lsme_8xVGx4_1x_j_loop:
    ldr     s3, [x11], #4
    dup     z3.s, z3.s[0]

    ld1w    {z4.s-z7.s}, pn8/z, [x12]
    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_1x_j_loop

.Lsme_8xVGx4_1x_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    ld1w    {z20.s-z23.s}, pn8/z, [x2, x7, lsl #2]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn8, [x2, x7, lsl #2]

.Lsme_8xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret


.global _sgemv_sme4xVGx4
.p2align 4

/// alpha   s0
/// beta    s1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.s = dup alpha
//  z1.s = dup beta
//
//  x5 = cntw
//  x6 = columns remaining
//  x7 = i
//
//  keep 4xVGx4 worth of A*x in ZA live, so 16 SVL's.
//
//  loop over i:
//      zero ZA
//      loop over j:
//          z3.s = dup x[j]
//          {z4.s-z7.s} = A[j * m + i .. j * m + i + 4 * x5]
//          za.s[w8, 0, vgx4] += {z4.s-z7.s} * z3.s
//          ...
//          za.s[w8, 3, vgx4] += {z16.s-z19.s} * z3.s
//      y[i .. i + 16 * x5] = z0.s * ZA + z1.s * y[i .. i + 16 * x5]
//
//  leftover rows:
//      keep 1xVGx4 worth of A*x in ZA live, so 4 SVL's.
_sgemv_sme4xVGx4:

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w5, s0
    fmov    w6, s1

    smstart
    ptrue   p0.s

    fmov    s0, w5
    dup     z0.s, z0.s[0]
    fmov    s1, w6
    dup     z1.s, z1.s[0]

    cntw    x5
    mov     x7, #0
    mov     w8, #0

    ptrue   pn8.s
    ptrue   pn9.s
    ptrue   pn10.s
    ptrue   pn11.s

.Lsme_4xVGx4_i_loop:
    cmp     x7, x3
    b.hs    .Lsme_4xVGx4_done

    sub     x9, x3, x7
    lsl     x10, x5, #2
    cmp     x9, x10
    b.ls    .Lsme_1xVGx4_tail

    mov     x12, x7
    add     x13, x12, x5, lsl #2
    add     x14, x13, x5, lsl #2
    add     x15, x14, x5, lsl #2

    lsl     x10, x5, #4
    cmp     x9, x10
    b.hs    .Lsme_4xVGx4_load

    whilelo pn8.s, x12, x3, vlx4
    b.none  .Lsme_4xVGx4_done
    whilelo pn9.s, x13, x3, vlx4
    whilelo pn10.s, x14, x3, vlx4
    whilelo pn11.s, x15, x3, vlx4

.Lsme_4xVGx4_load:
    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #2
    lsl     x13, x3, #2

    cbz     x6, .Lsme_4xVGx4_store

.Lsme_4xVGx4_j_loop:
    ldr     s3, [x11], #4
    dup     z3.s, z3.s[0]

    ld1w    {z4.s-z7.s}, pn8/z, [x12]
    ld1w    {z8.s-z11.s}, pn9/z, [x12, #4, mul vl]
    ld1w    {z12.s-z15.s}, pn10/z, [x12, #8, mul vl]
    ld1w    {z16.s-z19.s}, pn11/z, [x12, #12, mul vl]

    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s
    fmla    za.s[w8, 1, vgx4], {z8.s-z11.s}, z3.s
    fmla    za.s[w8, 2, vgx4], {z12.s-z15.s}, z3.s
    fmla    za.s[w8, 3, vgx4], {z16.s-z19.s}, z3.s

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_4xVGx4_j_loop

.Lsme_4xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    add     x10, x2, x7, lsl #2
    ld1w    {z20.s-z23.s}, pn8/z, [x10]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn8, [x10]

    mov     {z4.s-z7.s}, za.s[w8, 1, vgx4]
    ld1w    {z20.s-z23.s}, pn9/z, [x10, #4, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn9, [x10, #4, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 2, vgx4]
    ld1w    {z20.s-z23.s}, pn10/z, [x10, #8, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn10, [x10, #8, mul vl]

    mov     {z4.s-z7.s}, za.s[w8, 3, vgx4]
    ld1w    {z20.s-z23.s}, pn11/z, [x10, #12, mul vl]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn11, [x10, #12, mul vl]

    incw    x7, all, mul #16
    b       .Lsme_4xVGx4_i_loop

.Lsme_1xVGx4_tail:
    whilelo pn8.s, x7, x3, vlx4
    b.none  .Lsme_4xVGx4_done

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #2
    lsl     x13, x3, #2

    cbz     x6, .Lsme_1xVGx4_store

.Lsme_1xVGx4_j_loop:
    ldr     s3, [x11], #4
    dup     z3.s, z3.s[0]

    ld1w    {z4.s-z7.s}, pn8/z, [x12]
    fmla    za.s[w8, 0, vgx4], {z4.s-z7.s}, z3.s

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_1xVGx4_j_loop

.Lsme_1xVGx4_store:
    mov     {z4.s-z7.s}, za.s[w8, 0, vgx4]
    ld1w    {z20.s-z23.s}, pn8/z, [x2, x7, lsl #2]
    fmul    z20.s, z20.s, z1.s
    fmul    z21.s, z21.s, z1.s
    fmul    z22.s, z22.s, z1.s
    fmul    z23.s, z23.s, z1.s
    fmla    z20.s, p0/m, z4.s, z0.s
    fmla    z21.s, p0/m, z5.s, z0.s
    fmla    z22.s, p0/m, z6.s, z0.s
    fmla    z23.s, p0/m, z7.s, z0.s
    st1w    {z20.s-z23.s}, pn8, [x2, x7, lsl #2]

.Lsme_4xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
