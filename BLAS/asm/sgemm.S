.text

.global _sgemm_sme_kernel
.p2align 4
_sgemm_sme_kernel:
    sub     sp, sp, #96
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]
    stp     x19, x20, [sp, #64]
    stp     x21, x24, [sp, #80]

    mov     x24, x0
    ldr     w20, [x24, #88]
    ldr     w21, [x24, #92]
    smstart
    fmov    s6, w20
    fmov    s7, w21
    dup     z6.s, z6.s[0]
    dup     z7.s, z7.s[0]

    ldp     x0, x1, [x24]
    ldp     x2, x3, [x24, #16]
    ldp     x4, x5, [x24, #32]
    ldp     x6, x7, [x24, #48]
    ldp     x8, x9, [x24, #64]
    ldr     x10, [x24, #80]
    cntw    x11                 // V floats per Z register
    lsl     x13, x11, #1        // 2V rows and columns per output tile

    mov     x14, #0            // j0
                               // 
.Lcolumns:
    cmp     x14, x4
    b.hs    .Ldone
    whilelo p2.s, x14, x4
    add     x21, x14, x11
    whilelo p3.s, x21, x4
    whilelo pn9.s, x14, x4, vlx2

    mov     x15, #0            // i0
                               // 
.Lrows:
    cmp     x15, x3
    b.hs    .Lnext_columns
    whilelo p0.s, x15, x3
    add     x21, x15, x11
    whilelo p1.s, x21, x3
    whilelo pn8.s, x15, x3, vlx2

    zero    {za}
    madd    x16, x15, x6, x0   // A at row tile i0
    madd    x17, x14, x7, x1   // B at column tile j0
    mov     x20, x5
    cbz     x20, .Lstore

.Lreduce:
    ld1w    {z0.s, z1.s}, pn8/z, [x16]
    ld1w    {z2.s, z3.s}, pn9/z, [x17]

    fmopa   za0.s, p0/m, p2/m, z0.s, z2.s
    fmopa   za1.s, p0/m, p3/m, z0.s, z3.s
    fmopa   za2.s, p1/m, p2/m, z1.s, z2.s
    fmopa   za3.s, p1/m, p3/m, z1.s, z3.s

    add     x16, x16, x8
    add     x17, x17, x9
    subs    x20, x20, #1
    b.ne    .Lreduce

// ZA0/ZA2 are the lower V columns; 
// ZA1/ZA3 are the upper V.
.Lstore:
    madd    x19, x14, x10, x2
    add     x19, x19, x15, lsl #2
    mov     w12, #0

.Lstore_lower:
    add     x21, x14, x12
    cmp     x21, x4
    b.hs    .Lnext_rows

    mov     z0.s, p0/m, za0v.s[w12, 0]
    mov     z1.s, p1/m, za2v.s[w12, 0]
    ld1w    {z2.s, z3.s}, pn8/z, [x19]

    fmul    z0.s, z0.s, z6.s
    fmul    z1.s, z1.s, z6.s
    fmla    z0.s, p0/m, z2.s, z7.s
    fmla    z1.s, p1/m, z3.s, z7.s

    st1w    {z0.s, z1.s}, pn8, [x19]

    add     x19, x19, x10
    add     w12, w12, #1
    cmp     x12, x11
    b.lo    .Lstore_lower

    mov     w12, #0

.Lstore_upper:
    add     x21, x14, x11
    add     x21, x21, x12

    cmp     x21, x4
    b.hs    .Lnext_rows
    mov     z0.s, p0/m, za1v.s[w12, 0]
    mov     z1.s, p1/m, za3v.s[w12, 0]

    ld1w    {z2.s, z3.s}, pn8/z, [x19]
    fmul    z0.s, z0.s, z6.s
    fmul    z1.s, z1.s, z6.s
    fmla    z0.s, p0/m, z2.s, z7.s
    fmla    z1.s, p1/m, z3.s, z7.s

    st1w    {z0.s, z1.s}, pn8, [x19]

    add     x19, x19, x10
    add     w12, w12, #1
    cmp     x12, x11
    b.lo    .Lstore_upper


.Lnext_rows:
    add     x15, x15, x13
    b       .Lrows
.Lnext_columns:
    add     x14, x14, x13
    b       .Lcolumns
.Ldone:
    smstop

    ldp     d8, d9, [sp]
    ldp     d10, d11, [sp, #16]
    ldp     d12, d13, [sp, #32]
    ldp     d14, d15, [sp, #48]
    ldp     x19, x20, [sp, #64]
    ldp     x21, x24, [sp, #80]
    add     sp, sp, #96

    ret

.global _sgemm_svl_words
.p2align 4
_sgemm_svl_words:
    rdsvl   x0, #1
    lsr     x0, x0, #2
    ret
