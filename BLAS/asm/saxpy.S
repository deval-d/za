.text

.global _saxpy_asm 
.p2align 4 

_saxpy_asm:
    cmp     x2, #512 
    b.lo    _saxpy_neon 

    rdsvl   x15, #1 
    cmp     x15, #32 
    b.lo    _saxpy_sme4xVGx4 
    b       _saxpy_sme8xVGx4


.global _saxpy_neon
.p2align 4 

_saxpy_neon:
    lsr     x3, x2, #4 
    and     x4, x2, #15 
    lsr     x4, x4, #2 
    and     x5, x2, #3 

    cbz     x3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 
    ldp     q16, q17, [x1]
    ldp     q18, q19, [x1, #32]

    fmla    v16.4s, v4.4s, v0.s[0]
    fmla    v17.4s, v5.4s, v0.s[0]
    fmla    v18.4s, v6.4s, v0.s[0]
    fmla    v19.4s, v7.4s, v0.s[0]

    st1     {v16.4s-v19.4s}, [x1], #64 
    
    subs    x3, x3, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     x4, .Lscalar 

.Lsimd_4_loop:
    ldr     q4, [x0], #16 
    ldr     q16, [x1]

    fmla    v16.4s, v4.4s, v0.s[0]

    str     q16, [x1], #16 

    subs    x4, x4, #1 
    b.ne    .Lsimd_4_loop 

.Lscalar:
    cbz     x5, .Lneon_return 

.Lscalar_loop:
    ldr     s4, [x0], #4
    ldr     s16, [x1]

    fmadd   s16, s4, s0, s16 

    str     s16, [x1], #4 

    subs    x5, x5, #1 
    b.ne    .Lscalar_loop 

.Lneon_return:
    ret


.global _saxpy_sme4xVGx4
.p2align 4 

_saxpy_sme4xVGx4:
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0 

    smstart 
    
    fmov    s0, w3 
    dup     z0.s, z0.s[0]

    cntw    x3          // number of floats in SVL
    lsl     x4, x3, #2  // number of floats in VGx4 
    lsl     x5, x4, #2  // number of floats in 4xVGx4 
    
    mov     w8, #0 
    mov     x9, #0 

    udiv    x6, x2, x5  // number of full 4xVGx4 chunks 
    cbz     x6, .L4xVGx4_predicated 

    ptrue   pn8.s 

.L4xVGx4_full:
    add     x10, x9, x4 
    add     x11, x9, x4, lsl #1 
    add     x12, x10, x4, lsl #1 

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x9, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x1, x10, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x1, x11, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x12, lsl #2]

    mova    za.s[w8, #0, vgx4], {z4.s-z7.s} 
    mova    za.s[w8, #1, vgx4], {z8.s-z11.s}
    mova    za.s[w8, #2, vgx4], {z12.s-z15.s}
    mova    za.s[w8, #3, vgx4], {z16.s-z19.s}

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x12, lsl #2]

    fmla    za.s[w8, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, #3, vgx4], {z16.s-z19.s}, z0.s

    mova    {z4.s-z7.s}, za.s[w8, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w8, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w8, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w8, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x1, x9, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x10, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x11, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x1, x12, lsl #2] 

    add     x9, x9, x5
    subs    x6, x6, #1 
    b.ne    .L4xVGx4_full

.L4xVGx4_predicated:
    add     x10, x9, x4 
    add     x11, x9, x4, lsl #1 
    add     x12, x10, x4, lsl #1 

    whilelo pn8.s, x9, x2, vlx4 
    b.none  .L4xVGx4_return 

    whilelo pn9.s, x10, x2, vlx4
    whilelo pn10.s, x11, x2, vlx4
    whilelo pn11.s, x12, x2, vlx4

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x9, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x1, x10, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x1, x11, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x1, x12, lsl #2]

    mova    za.s[w8, #0, vgx4], {z4.s-z7.s} 
    mova    za.s[w8, #1, vgx4], {z8.s-z11.s}
    mova    za.s[w8, #2, vgx4], {z12.s-z15.s}
    mova    za.s[w8, #3, vgx4], {z16.s-z19.s}

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x10, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x11, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x12, lsl #2]

    fmla    za.s[w8, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, #3, vgx4], {z16.s-z19.s}, z0.s

    mova    {z4.s-z7.s}, za.s[w8, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w8, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w8, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w8, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x1, x9, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x1, x10, lsl #2]
    st1w    {z12.s-z15.s}, pn10, [x1, x11, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x1, x12, lsl #2]

.L4xVGx4_return:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _saxpy_sme8xVGx4
.p2align 4 

_saxpy_sme8xVGx4:
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0 

    smstart 
    
    fmov    s0, w3 
    dup     z0.s, z0.s[0]

    cntw    x3          // number of floats in SVL
    lsl     x4, x3, #2  // number of floats in VGx4 
    lsl     x5, x4, #3  // number of floats in 8xVGx4 
    
    mov     w8, #0 
    mov     x10, #0
    rdsvl   x9, #1 
    lsr     x9, x9, #3

    udiv    x6, x2, x5  // number of full 8xVGx4 chunks 
    cbz     x6, .L8xVGx4_predicated 

    ptrue   pn8.s 

.L8xVGx4_full:
    add     x11, x10, x4 
    add     x12, x10, x4, lsl #1 
    add     x13, x11, x4, lsl #1
    add     x14, x10, x4, lsl #2 
    add     x15, x11, x4, lsl #2 
    add     x16, x12, x4, lsl #2 
    add     x17, x13, x4, lsl #2 

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x10, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x1, x11, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x1, x12, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x13, lsl #2]

    mova    za.s[w8, #0, vgx4], {z4.s-z7.s} 
    mova    za.s[w8, #1, vgx4], {z8.s-z11.s}
    mova    za.s[w8, #2, vgx4], {z12.s-z15.s}
    mova    za.s[w8, #3, vgx4], {z16.s-z19.s}

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x14, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x1, x15, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x1, x16, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x17, lsl #2]

    mova    za.s[w9, #0, vgx4], {z4.s-z7.s} 
    mova    za.s[w9, #1, vgx4], {z8.s-z11.s}
    mova    za.s[w9, #2, vgx4], {z12.s-z15.s}
    mova    za.s[w9, #3, vgx4], {z16.s-z19.s}

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x11, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x12, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x13, lsl #2]

    fmla    za.s[w8, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, #3, vgx4], {z16.s-z19.s}, z0.s

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x14, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x15, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x16, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x17, lsl #2]

    fmla    za.s[w9, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w9, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w9, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w9, #3, vgx4], {z16.s-z19.s}, z0.s

    mova    {z4.s-z7.s}, za.s[w8, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w8, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w8, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w8, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x1, x10, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x11, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x12, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x1, x13, lsl #2] 

    mova    {z4.s-z7.s}, za.s[w9, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w9, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w9, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w9, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x1, x14, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x1, x15, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x1, x16, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x1, x17, lsl #2] 

    add     x10, x10, x5
    subs    x6, x6, #1 
    b.ne    .L8xVGx4_full

.L8xVGx4_predicated:
    add     x11, x10, x4 
    add     x12, x10, x4, lsl #1 
    add     x13, x11, x4, lsl #1 

    whilelo pn8.s, x10, x2, vlx4
    b.none  .L8xVGx4_return 

    whilelo pn9.s, x11, x2, vlx4 
    whilelo pn10.s, x12, x2, vlx4
    whilelo pn11.s, x13, x2, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x1, x10, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x1, x11, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x1, x12, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x1, x13, lsl #2]

    mova    za.s[w8, #0, vgx4], {z4.s-z7.s} 
    mova    za.s[w8, #1, vgx4], {z8.s-z11.s}
    mova    za.s[w8, #2, vgx4], {z12.s-z15.s}
    mova    za.s[w8, #3, vgx4], {z16.s-z19.s}

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x10, lsl #2]
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x11, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x12, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x13, lsl #2]

    fmla    za.s[w8, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w8, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w8, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w8, #3, vgx4], {z16.s-z19.s}, z0.s

    mova    {z4.s-z7.s}, za.s[w8, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w8, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w8, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w8, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x1, x10, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x1, x11, lsl #2]
    st1w    {z12.s-z15.s}, pn10, [x1, x12, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x1, x13, lsl #2]

    add     x10, x10, x4, lsl #2 
    b       .L8xVGx4_predicated

.L8xVGx4_return:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret
