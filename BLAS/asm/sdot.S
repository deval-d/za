.text

.global _sdot_asm
.p2align 4 

_sdot_asm:
    cmp     x2, #1600
    b.lo    _sdot_neon 
    b       _sdot_sme4xVGx4

.global _sdot_neon
.p2align 4 

_sdot_neon:
    lsr     x3, x2, #4 
    and     x4, x2, #15 
    lsr     x4, x4, #2 
    and     x5, x2, #3 

    // independent accumulators 
    movi    v0.4s, #0 
    movi    v1.4s, #0 
    movi    v2.4s, #0
    movi    v3.4s, #0 

    cbz     x3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32
    ldp     q16, q17, [x1], #32
    ldp     q18, q19, [x1], #32

    fmla    v0.4s, v4.4s, v16.4s 
    fmla    v1.4s, v5.4s, v17.4s 
    fmla    v2.4s, v6.4s, v18.4s 
    fmla    v3.4s, v7.4s, v19.4s 

    subs    x3, x3, #1 
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     x4, .Lneon_reduce

.Lsimd_4_loop:
    ldr     q4, [x0], #16 
    ldr     q16, [x1], #16

    fmla    v0.4s, v4.4s, v16.4s 

    subs    x4, x4, #1 
    b.ne    .Lsimd_4_loop 

.Lneon_reduce:
    fadd    v0.4s, v0.4s, v2.4s 
    fadd    v1.4s, v1.4s, v3.4s 
    fadd    v0.4s, v0.4s, v1.4s 
    faddp   v0.4s, v0.4s, v0.4s 
    faddp   s0, v0.2s 

.Lscalar:
    cbz     x5, .Lneon_return 

.Lscalar_loop:
    ldr     s4, [x0], #4 
    ldr     s16, [x1], #4 

    fmadd   s0, s4, s16, s0 

    subs    x5, x5, #1 
    b.ne    .Lscalar_loop 

.Lneon_return:
    ret 



.global _sdot_sme4xVGx4
.p2align 4 

_sdot_sme4xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    cntw    x3          // floats in SVL
    lsl     x4, x3, #2  // floats in VGx4 
    lsl     x5, x4, #2  // floats in 4xVGx4 
    
    mov     x7, #0
    mov     w11, #0

    udiv    x6, x2, x5  // number of full 4xVGx4 
    cbz     x6, .L4xVGx4_predicated

    ptrue   pn8.s 

.L4xVGx4_full:
    add     x8, x7, x4 
    add     x9, x7, x4, lsl #1 
    add     x10, x8, x4, lsl #1 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x10, lsl #2]
    
    ld1w    {z16.s-z19.s}, pn8/z, [x1, x7, lsl #2]
    ld1w    {z20.s-z23.s}, pn8/z, [x1, x8, lsl #2]
    ld1w    {z24.s-z27.s}, pn8/z, [x1, x9, lsl #2]
    ld1w    {z28.s-z31.s}, pn8/z, [x1, x10, lsl #2] 

    fmla    za.s[w11, #0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w11, #1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w11, #2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w11, #3, vgx4], {z12.s-z15.s}, {z28.s-z31.s} 

    add     x7, x7, x5 

    subs    x6, x6, #1
    b.ne    .L4xVGx4_full 

.L4xVGx4_predicated:
    add     x8, x7, x4 
    add     x9, x7, x4, lsl #1 
    add     x10, x8, x4, lsl #1 

    whilelo pn8.s, x7, x2, vlx4 
    b.none  .L4xVGx4_reduce 

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

    fmla    za.s[w11, #0, vgx4], {z0.s-z3.s}, {z16.s-z19.s}
    fmla    za.s[w11, #1, vgx4], {z4.s-z7.s}, {z20.s-z23.s}
    fmla    za.s[w11, #2, vgx4], {z8.s-z11.s}, {z24.s-z27.s}
    fmla    za.s[w11, #3, vgx4], {z12.s-z15.s}, {z28.s-z31.s} 

.L4xVGx4_reduce:
    ptrue p0.s

    mova    {z0.s-z3.s}, za.s[w11, #1, vgx4]
    mova    {z4.s-z7.s}, za.s[w11, #2, vgx4]
    mova    {z8.s-z11.s}, za.s[w11, #3, vgx4]

    fadd    za.s[w11, #0, vgx4], {z0.s-z3.s}
    fadd    za.s[w11, #0, vgx4], {z4.s-z7.s}
    fadd    za.s[w11, #0, vgx4], {z8.s-z11.s}

    mova    {z0.s-z3.s}, za.s[w11, #0, vgx4]

    fadd    z0.s, z0.s, z1.s 
    fadd    z2.s, z2.s, z3.s 
    fadd    z0.s, z0.s, z2.s 
    faddv   s0, p0, z0.s 

.L4xVGx4_return:
    fmov    w3, s0 

    smstop

    fmov    s0, w3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
    
