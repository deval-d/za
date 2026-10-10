.text
.arch_extension sme-f64f64

.global _dgemv
.p2align 4

_dgemv:
    cmp     w3, #16
    b.ls    _dgemv_neon

    mul     w5, w3, w4
    cmp     w5, #1536
    b.ls    _dgemv_neon

    cmp     w3, #32
    b.hi    _dgemv_sme
    cmp     w4, #64
    b.ls    _dgemv_neon
    b       _dgemv_sme


.global _dgemv_neon
.p2align 4

_dgemv_neon:
    cmp     w3, #16
    b.ls    _dgemv_neon_i_outer

    mul     w5, w3, w4
    cmp     w5, #2048
    b.ls    _dgemv_neon_i_outer

    cmp     w3, #32
    b.hi    _dgemv_neon_j_outer
    cmp     w4, #128
    b.ls    _dgemv_neon_i_outer
    b       _dgemv_neon_j_outer


.global _dgemv_neon_i_outer
.p2align 4

_dgemv_neon_i_outer:
    mov     w5, #0
    cmp     w3, #8
    b.lo    .Li_rows2

.Li_rows8_loop:
    add     x9, x2, w5, uxtw #3
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    fmul    v16.2d, v16.2d, v1.d[0]
    fmul    v17.2d, v17.2d, v1.d[0]
    fmul    v18.2d, v18.2d, v1.d[0]
    fmul    v19.2d, v19.2d, v1.d[0]

    mov     w6, #0

.Li_8x2_loop:
    add     w8, w6, #2
    cmp     w8, w4
    b.hi    .Li_8x1

    add     x10, x1, w6, uxtw #3
    ldr     q20, [x10]
    fmul    v20.2d, v20.2d, v0.d[0]

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #3

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.2d, v21.2d, v20.d[0]
    fmla    v17.2d, v22.2d, v20.d[0]
    fmla    v18.2d, v23.2d, v20.d[0]
    fmla    v19.2d, v24.2d, v20.d[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #3
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.2d, v21.2d, v20.d[1]
    fmla    v17.2d, v22.2d, v20.d[1]
    fmla    v18.2d, v23.2d, v20.d[1]
    fmla    v19.2d, v24.2d, v20.d[1]

    mov     w6, w8
    b       .Li_8x2_loop

.Li_8x1:
    cmp     w6, w4
    b.hs    .Li_8_store

.Li_8x1_loop:
    add     x10, x1, w6, uxtw #3
    ldr     d20, [x10]
    fmul    d20, d20, d0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #3
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.2d, v21.2d, v20.d[0]
    fmla    v17.2d, v22.2d, v20.d[0]
    fmla    v18.2d, v23.2d, v20.d[0]
    fmla    v19.2d, v24.2d, v20.d[0]

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_8x1_loop

.Li_8_store:
    add     x9, x2, w5, uxtw #3
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w5, w5, #8
    sub     w7, w3, w5
    cmp     w7, #8
    b.hs    .Li_rows8_loop

.Li_rows2:
    sub     w7, w3, w5
    cmp     w7, #2
    b.lo    .Li_scalar

.Li_rows2_loop:
    add     x9, x2, w5, uxtw #3
    ldr     q16, [x9]
    fmul    v16.2d, v16.2d, v1.d[0]

    mov     w6, #0

.Li_2x2_loop:
    add     w8, w6, #2
    cmp     w8, w4
    b.hi    .Li_2x1

    add     x10, x1, w6, uxtw #3
    ldr     q20, [x10]
    fmul    v20.2d, v20.2d, v0.d[0]

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[1]

    mov     w6, w8
    b       .Li_2x2_loop

.Li_2x1:
    cmp     w6, w4
    b.hs    .Li_2_store

.Li_2x1_loop:
    add     x10, x1, w6, uxtw #3
    ldr     d20, [x10]
    fmul    d20, d20, d0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[0]

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_2x1_loop

.Li_2_store:
    add     x9, x2, w5, uxtw #3
    str     q16, [x9]

    add     w5, w5, #2
    sub     w7, w3, w5
    cmp     w7, #2
    b.hs    .Li_rows2_loop

.Li_scalar:
    cmp     w5, w3
    b.hs    .Li_done

.Li_scalar_row_loop:
    add     x9, x2, w5, uxtw #3
    ldr     d16, [x9]
    fmul    d16, d16, d1

    mov     w6, #0
    cbz     w4, .Li_scalar_store

.Li_scalar_col_loop:
    add     x10, x1, w6, uxtw #3
    ldr     d20, [x10]
    fmul    d20, d20, d0

    madd    w7, w6, w3, w5
    add     x10, x0, w7, uxtw #3
    ldr     d21, [x10]
    fmadd   d16, d21, d20, d16

    add     w6, w6, #1
    cmp     w6, w4
    b.lo    .Li_scalar_col_loop

.Li_scalar_store:
    str     d16, [x9]
    add     w5, w5, #1
    cmp     w5, w3
    b.lo    .Li_scalar_row_loop

.Li_done:
    ret


.global _dgemv_neon_j_outer
.p2align 4

_dgemv_neon_j_outer:
    mov     w5, #0
    cmp     w4, #2
    b.lo    .Lj_cols1

.Lj_cols2_loop:
    add     x9, x1, w5, uxtw #3
    ldr     q20, [x9]
    fmul    v20.2d, v20.2d, v0.d[0]

    mov     w6, #0
    cmp     w3, #8
    b.lo    .Lj_2_rows2

.Lj_2_rows8_loop:
    add     x9, x2, w6, uxtw #3
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    w5, .Lj_2_rows8_accumulate
    fmul    v16.2d, v16.2d, v1.d[0]
    fmul    v17.2d, v17.2d, v1.d[0]
    fmul    v18.2d, v18.2d, v1.d[0]
    fmul    v19.2d, v19.2d, v1.d[0]

.Lj_2_rows8_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3

    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.2d, v21.2d, v20.d[0]
    fmla    v17.2d, v22.2d, v20.d[0]
    fmla    v18.2d, v23.2d, v20.d[0]
    fmla    v19.2d, v24.2d, v20.d[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #3
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]
    fmla    v16.2d, v21.2d, v20.d[1]
    fmla    v17.2d, v22.2d, v20.d[1]
    fmla    v18.2d, v23.2d, v20.d[1]
    fmla    v19.2d, v24.2d, v20.d[1]

    add     x9, x2, w6, uxtw #3
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w6, w6, #8
    sub     w7, w3, w6
    cmp     w7, #8
    b.hs    .Lj_2_rows8_loop

.Lj_2_rows2:
    sub     w7, w3, w6
    cmp     w7, #2
    b.lo    .Lj_2_scalar

.Lj_2_rows2_loop:
    add     x9, x2, w6, uxtw #3
    ldr     q16, [x9]

    cbnz    w5, .Lj_2_rows2_accumulate
    fmul    v16.2d, v16.2d, v1.d[0]

.Lj_2_rows2_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[0]

    add     w7, w7, w3
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[1]

    add     x9, x2, w6, uxtw #3
    str     q16, [x9]

    add     w6, w6, #2
    sub     w7, w3, w6
    cmp     w7, #2
    b.hs    .Lj_2_rows2_loop

.Lj_2_scalar:
    cmp     w6, w3
    b.hs    .Lj_2_next

.Lj_2_scalar_loop:
    add     x9, x2, w6, uxtw #3
    ldr     d16, [x9]

    cbnz    w5, .Lj_2_scalar_accumulate
    fmul    d16, d16, d1

.Lj_2_scalar_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3

    ldr     d21, [x10]
    fmla    d16, d21, v20.d[0]
    add     w7, w7, w3
    add     x10, x0, w7, uxtw #3
    ldr     d21, [x10]
    fmla    d16, d21, v20.d[1]

    str     d16, [x9]
    add     w6, w6, #1
    cmp     w6, w3
    b.lo    .Lj_2_scalar_loop

.Lj_2_next:
    add     w5, w5, #2
    sub     w7, w4, w5
    cmp     w7, #2
    b.hs    .Lj_cols2_loop

.Lj_cols1:
    cmp     w5, w4
    b.hs    .Lj_done

.Lj_cols1_loop:
    add     x9, x1, w5, uxtw #3
    ldr     d20, [x9]
    fmul    d20, d20, d0

    mov     w6, #0
    cmp     w3, #8
    b.lo    .Lj_1_rows2

.Lj_1_rows8_loop:
    add     x9, x2, w6, uxtw #3
    ldp     q16, q17, [x9]
    ldp     q18, q19, [x9, #32]

    cbnz    w5, .Lj_1_rows8_accumulate
    fmul    v16.2d, v16.2d, v1.d[0]
    fmul    v17.2d, v17.2d, v1.d[0]
    fmul    v18.2d, v18.2d, v1.d[0]
    fmul    v19.2d, v19.2d, v1.d[0]

.Lj_1_rows8_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3
    ldp     q21, q22, [x10]
    ldp     q23, q24, [x10, #32]

    fmla    v16.2d, v21.2d, v20.d[0]
    fmla    v17.2d, v22.2d, v20.d[0]
    fmla    v18.2d, v23.2d, v20.d[0]
    fmla    v19.2d, v24.2d, v20.d[0]

    add     x9, x2, w6, uxtw #3
    stp     q16, q17, [x9]
    stp     q18, q19, [x9, #32]

    add     w6, w6, #8
    sub     w7, w3, w6
    cmp     w7, #8
    b.hs    .Lj_1_rows8_loop

.Lj_1_rows2:
    sub     w7, w3, w6
    cmp     w7, #2
    b.lo    .Lj_1_scalar

.Lj_1_rows2_loop:
    add     x9, x2, w6, uxtw #3
    ldr     q16, [x9]

    cbnz    w5, .Lj_1_rows2_accumulate
    fmul    v16.2d, v16.2d, v1.d[0]

.Lj_1_rows2_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3
    ldr     q21, [x10]
    fmla    v16.2d, v21.2d, v20.d[0]
    str     q16, [x9]

    add     w6, w6, #2
    sub     w7, w3, w6
    cmp     w7, #2
    b.hs    .Lj_1_rows2_loop

.Lj_1_scalar:
    cmp     w6, w3
    b.hs    .Lj_1_next

.Lj_1_scalar_loop:
    add     x9, x2, w6, uxtw #3
    ldr     d16, [x9]

    cbnz    w5, .Lj_1_scalar_accumulate
    fmul    d16, d16, d1

.Lj_1_scalar_accumulate:
    madd    w7, w5, w3, w6
    add     x10, x0, w7, uxtw #3
    ldr     d21, [x10]
    fmadd   d16, d21, d20, d16
    str     d16, [x9]

    add     w6, w6, #1
    cmp     w6, w3
    b.lo    .Lj_1_scalar_loop

.Lj_1_next:
    add     w5, w5, #1
    cmp     w5, w4
    b.lo    .Lj_cols1_loop

.Lj_done:
    ret


.global _dgemv_sme
.p2align 4

_dgemv_sme:
    rdsvl   x5, #1
    cmp     x5, #32
    b.lo    _dgemv_sme4xVGx4

    lsl     x6, x5, #2
    cmp     x3, x6
    b.lo    _dgemv_sme4xVGx4

    umull   x5, w3, w4
    mov     w6, #1536
    mul     w6, w6, w6
    cmp     x5, x6
    b.ls    _dgemv_sme8xVGx4
    b       _dgemv_sme4xVGx4


.global _dgemv_sme4xVGx4
.p2align 4

/// alpha   d0
/// beta    d1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.d = dup alpha
//  z1.d = dup beta
//
//  x5 = cntd
//  x6 = columns remaining
//  x7 = i
//
//  keep 4xVGx4 worth of A*x in ZA live, so 16 SVL's.
//
//  loop over i:
//      zero ZA
//      loop over j:
//          z3.d = dup x[j]
//          {z4.d-z7.d} = A[j * m + i .. j * m + i + 4 * x5]
//          za.d[w8, 0, vgx4] += {z4.d-z7.d} * z3.d
//          ...
//          za.d[w8, 3, vgx4] += {z16.d-z19.d} * z3.d
//      y[i .. i + 16 * x5] = z0.d * ZA + z1.d * y[i .. i + 16 * x5]
//
//  leftover rows:
//      keep 1xVGx4 worth of A*x in ZA live, so 4 SVL's.
_dgemv_sme4xVGx4:
    mov     w3, w3
    mov     w4, w4

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x5, d0
    fmov    x6, d1

    smstart

    fmov    d0, x5
    dup     z0.d, z0.d[0]
    fmov    d1, x6
    dup     z1.d, z1.d[0]

    cntd    x5
    mov     x7, #0
    mov     w8, #0

    ptrue   pn8.d
    ptrue   pn9.d
    ptrue   pn10.d
    ptrue   pn11.d

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

    whilelo pn8.d, x12, x3, vlx4
    b.none  .Lsme_4xVGx4_done
    whilelo pn9.d, x13, x3, vlx4
    whilelo pn10.d, x14, x3, vlx4
    whilelo pn11.d, x15, x3, vlx4

.Lsme_4xVGx4_load:
    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #3
    lsl     x13, x3, #3

    cbz     x6, .Lsme_4xVGx4_store

.Lsme_4xVGx4_j_loop:
    ldr     d3, [x11], #8
    dup     z3.d, z3.d[0]

    ld1d    {z4.d-z7.d}, pn8/z, [x12]
    ld1d    {z8.d-z11.d}, pn9/z, [x12, #4, mul vl]
    ld1d    {z12.d-z15.d}, pn10/z, [x12, #8, mul vl]
    ld1d    {z16.d-z19.d}, pn11/z, [x12, #12, mul vl]

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z3.d
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z3.d
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z3.d
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z3.d

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_4xVGx4_j_loop

.Lsme_4xVGx4_store:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    add     x10, x2, x7, lsl #3
    ld1d    {z20.d-z23.d}, pn8/z, [x10]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn8, [x10]

    mov     {z4.d-z7.d}, za.d[w8, 1, vgx4]
    ld1d    {z20.d-z23.d}, pn9/z, [x10, #4, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn9, [x10, #4, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 2, vgx4]
    ld1d    {z20.d-z23.d}, pn10/z, [x10, #8, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn10, [x10, #8, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 3, vgx4]
    ld1d    {z20.d-z23.d}, pn11/z, [x10, #12, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn11, [x10, #12, mul vl]

    incd    x7, all, mul #16
    b       .Lsme_4xVGx4_i_loop

.Lsme_1xVGx4_tail:
    whilelo pn8.d, x7, x3, vlx4
    b.none  .Lsme_4xVGx4_done

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #3
    lsl     x13, x3, #3

    cbz     x6, .Lsme_1xVGx4_store

.Lsme_1xVGx4_j_loop:
    ldr     d3, [x11], #8
    dup     z3.d, z3.d[0]

    ld1d    {z4.d-z7.d}, pn8/z, [x12]
    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z3.d

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_1xVGx4_j_loop

.Lsme_1xVGx4_store:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    ld1d    {z20.d-z23.d}, pn8/z, [x2, x7, lsl #3]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn8, [x2, x7, lsl #3]

.Lsme_4xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret


.global _dgemv_sme8xVGx4
.p2align 4

/// alpha   d0
/// beta    d1
//  *a      x0
//  *x      x1
//  *y      x2
//  m       x3
//  n       x4
//
//  z0.d = dup alpha
//  z1.d = dup beta
//
//  x5 = cntd
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
//          z3.d = dup x[j]
//          {z4.d-z7.d} = A[j * m + i .. j * m + i + 4 * x5]
//          za.d[w8, 0, vgx4] += {z4.d-z7.d} * z3.d
//          ...
//          za.d[w9, 3, vgx4] += {z16.d-z19.d} * z3.d
//      y[i .. i + 32 * x5] = z0.d * ZA + z1.d * y[i .. i + 32 * x5]
//
//  leftover rows:
//      keep 4xVGx4 or 1xVGx4 worth of A*x in ZA live.
_dgemv_sme8xVGx4:
    mov     w3, w3
    mov     w4, w4

    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x5, d0
    fmov    x6, d1

    smstart

    fmov    d0, x5
    dup     z0.d, z0.d[0]
    fmov    d1, x6
    dup     z1.d, z1.d[0]

    cntd    x5
    mov     x7, #0
    mov     w8, #0
    lsr     w9, w5, #1

    ptrue   pn8.d
    ptrue   pn9.d
    ptrue   pn10.d
    ptrue   pn11.d
    ptrue   pn12.d
    ptrue   pn13.d
    ptrue   pn14.d
    ptrue   pn15.d

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
    whilelo pn8.d, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn12.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn13.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn14.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn15.d, x10, x3, vlx4

.Lsme_8xVGx4_load:
    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #3
    lsl     x13, x3, #3

    cbz     x6, .Lsme_8xVGx4_store

.Lsme_8xVGx4_j_loop:
    ldr     d3, [x11], #8
    dup     z3.d, z3.d[0]

    ld1d    {z4.d-z7.d}, pn8/z, [x12]
    ld1d    {z8.d-z11.d}, pn9/z, [x12, #4, mul vl]
    ld1d    {z12.d-z15.d}, pn10/z, [x12, #8, mul vl]
    ld1d    {z16.d-z19.d}, pn11/z, [x12, #12, mul vl]

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z3.d
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z3.d
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z3.d
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z3.d

    add     x10, x12, x5, lsl #7
    ld1d    {z4.d-z7.d}, pn12/z, [x10]
    ld1d    {z8.d-z11.d}, pn13/z, [x10, #4, mul vl]
    ld1d    {z12.d-z15.d}, pn14/z, [x10, #8, mul vl]
    ld1d    {z16.d-z19.d}, pn15/z, [x10, #12, mul vl]

    fmla    za.d[w9, 0, vgx4], {z4.d-z7.d}, z3.d
    fmla    za.d[w9, 1, vgx4], {z8.d-z11.d}, z3.d
    fmla    za.d[w9, 2, vgx4], {z12.d-z15.d}, z3.d
    fmla    za.d[w9, 3, vgx4], {z16.d-z19.d}, z3.d

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_j_loop

.Lsme_8xVGx4_store:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    add     x10, x2, x7, lsl #3
    ld1d    {z20.d-z23.d}, pn8/z, [x10]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn8, [x10]

    mov     {z4.d-z7.d}, za.d[w8, 1, vgx4]
    ld1d    {z20.d-z23.d}, pn9/z, [x10, #4, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn9, [x10, #4, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 2, vgx4]
    ld1d    {z20.d-z23.d}, pn10/z, [x10, #8, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn10, [x10, #8, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 3, vgx4]
    ld1d    {z20.d-z23.d}, pn11/z, [x10, #12, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn11, [x10, #12, mul vl]

    add     x10, x10, x5, lsl #7

    mov     {z4.d-z7.d}, za.d[w9, 0, vgx4]
    ld1d    {z20.d-z23.d}, pn12/z, [x10]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn12, [x10]

    mov     {z4.d-z7.d}, za.d[w9, 1, vgx4]
    ld1d    {z20.d-z23.d}, pn13/z, [x10, #4, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn13, [x10, #4, mul vl]

    mov     {z4.d-z7.d}, za.d[w9, 2, vgx4]
    ld1d    {z20.d-z23.d}, pn14/z, [x10, #8, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn14, [x10, #8, mul vl]

    mov     {z4.d-z7.d}, za.d[w9, 3, vgx4]
    ld1d    {z20.d-z23.d}, pn15/z, [x10, #12, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn15, [x10, #12, mul vl]

    incd    x7, all, mul #16
    incd    x7, all, mul #16
    b       .Lsme_8xVGx4_i_loop

.Lsme_8xVGx4_4x_tail:
    mov     x10, x7
    whilelo pn8.d, x10, x3, vlx4
    b.none  .Lsme_8xVGx4_done
    add     x10, x10, x5, lsl #2
    whilelo pn9.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn10.d, x10, x3, vlx4
    add     x10, x10, x5, lsl #2
    whilelo pn11.d, x10, x3, vlx4

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #3
    lsl     x13, x3, #3

    cbz     x6, .Lsme_8xVGx4_4x_store

.Lsme_8xVGx4_4x_j_loop:
    ldr     d3, [x11], #8
    dup     z3.d, z3.d[0]

    ld1d    {z4.d-z7.d}, pn8/z, [x12]
    ld1d    {z8.d-z11.d}, pn9/z, [x12, #4, mul vl]
    ld1d    {z12.d-z15.d}, pn10/z, [x12, #8, mul vl]
    ld1d    {z16.d-z19.d}, pn11/z, [x12, #12, mul vl]

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z3.d
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z3.d
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z3.d
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z3.d

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_4x_j_loop

.Lsme_8xVGx4_4x_store:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    add     x10, x2, x7, lsl #3
    ld1d    {z20.d-z23.d}, pn8/z, [x10]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn8, [x10]

    mov     {z4.d-z7.d}, za.d[w8, 1, vgx4]
    ld1d    {z20.d-z23.d}, pn9/z, [x10, #4, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn9, [x10, #4, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 2, vgx4]
    ld1d    {z20.d-z23.d}, pn10/z, [x10, #8, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn10, [x10, #8, mul vl]

    mov     {z4.d-z7.d}, za.d[w8, 3, vgx4]
    ld1d    {z20.d-z23.d}, pn11/z, [x10, #12, mul vl]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn11, [x10, #12, mul vl]
    b       .Lsme_8xVGx4_done

.Lsme_8xVGx4_1x_tail:
    whilelo pn8.d, x7, x3, vlx4
    b.none  .Lsme_8xVGx4_done

    zero    {za}

    mov     x6, x4
    mov     x11, x1
    add     x12, x0, x7, lsl #3
    lsl     x13, x3, #3

    cbz     x6, .Lsme_8xVGx4_1x_store

.Lsme_8xVGx4_1x_j_loop:
    ldr     d3, [x11], #8
    dup     z3.d, z3.d[0]

    ld1d    {z4.d-z7.d}, pn8/z, [x12]
    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z3.d

    add     x12, x12, x13
    subs    x6, x6, #1
    b.ne    .Lsme_8xVGx4_1x_j_loop

.Lsme_8xVGx4_1x_store:
    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    ld1d    {z20.d-z23.d}, pn8/z, [x2, x7, lsl #3]
    fmul    z20.d, z20.d, z1.d
    fmul    z21.d, z21.d, z1.d
    fmul    z22.d, z22.d, z1.d
    fmul    z23.d, z23.d, z1.d
    fmul    z4.d, z4.d, z0.d
    fmul    z5.d, z5.d, z0.d
    fmul    z6.d, z6.d, z0.d
    fmul    z7.d, z7.d, z0.d
    fadd    z20.d, z20.d, z4.d
    fadd    z21.d, z21.d, z5.d
    fadd    z22.d, z22.d, z6.d
    fadd    z23.d, z23.d, z7.d
    st1d    {z20.d-z23.d}, pn8, [x2, x7, lsl #3]

.Lsme_8xVGx4_done:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
