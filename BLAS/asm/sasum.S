.text

.global _sasum_asm
.p2align 4 

_sasum_asm:
    cmp     x1, #4032
    b.lo    _sasum_neon 
    b       _sasum_sme4xVGx4


.global _sasum_neon 
.p2align 4 

_sasum_neon:
    lsr     x2, x1, #5 
    and     x3, x1, #31 
    lsr     x3, x3, #4 
    and     x4, x1, #15
    lsr     x4, x4, #2 
    and     x5, x1, #3 

    movi    v0.4s, #0 
    movi    v1.4s, #0 
    movi    v2.4s, #0
    movi    v3.4s, #0

    mov     w6, #0x7fffffff
    dup     v20.4s, w6
    cbz     x2, .Lsimd_16 

.Lsimd_32_loop:
    ldp     q4, q5, [x0], #32
    ldp     q6, q7, [x0], #32
    ldp     q16, q17, [x0], #32
    ldp     q18, q19, [x0], #32

    and     v4.16b, v4.16b, v20.16b 
    and     v5.16b, v5.16b, v20.16b 
    and     v6.16b, v6.16b, v20.16b 
    and     v7.16b, v7.16b, v20.16b 
    and     v16.16b, v16.16b, v20.16b 
    and     v17.16b, v17.16b, v20.16b 
    and     v18.16b, v18.16b, v20.16b 
    and     v19.16b, v19.16b, v20.16b 

    fadd     v4.4s, v4.4s, v5.4s 
    fadd     v6.4s, v6.4s, v7.4s 
    fadd     v16.4s, v16.4s, v17.4s 
    fadd     v18.4s, v18.4s, v19.4s 
    fadd     v0.4s, v0.4s, v4.4s 
    fadd     v1.4s, v1.4s, v6.4s 
    fadd     v2.4s, v2.4s, v16.4s 
    fadd     v3.4s, v3.4s, v18.4s 

    subs    x2, x2, #1 
    b.ne    .Lsimd_32_loop 

.Lsimd_16:
    cbz     x3, .Lsimd_4 

.Lsimd_16_loop:
    ldp     q4, q5, [x0], #32
    ldp     q6, q7, [x0], #32
     
    and     v4.16b, v4.16b, v20.16b
    and     v5.16b, v5.16b, v20.16b 
    and     v6.16b, v6.16b, v20.16b 
    and     v7.16b, v7.16b, v20.16b 

    fadd     v0.4s, v0.4s, v4.4s 
    fadd     v1.4s, v1.4s, v5.4s 
    fadd     v2.4s, v2.4s, v6.4s 
    fadd     v3.4s, v3.4s, v7.4s 

    subs    x3, x3, #1
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     x4, .Lneon_reduce 

.Lsimd_4_loop:
    ldr     q4, [x0], #16

    and     v4.16b, v4.16b, v20.16b 
    fadd     v0.4s, v0.4s,  v4.4s 

    subs    x4, x4, #1 
    b.ne    .Lsimd_4_loop

.Lneon_reduce:
    fadd     v0.4s, v0.4s, v1.4s 
    fadd     v2.4s, v2.4s, v3.4s 
    fadd     v0.4s, v0.4s, v2.4s 
    faddp   v0.4s, v0.4s, v0.4s 
    faddp   s0, v0.2s 

.Lscalar:
    cbz     x5, .Lneon_return 

.Lscalar_loop:
    ldr     s4, [x0], #4 

    fabs    s4, s4 
    fadd    s0, s0, s4 

    subs    x5, x5, #1
    b.ne    .Lscalar_loop 

.Lneon_return:
    ret 


.global _sasum_sme4xVGx4
.p2align 4 

_sasum_sme4xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    cntw    x2          // number of floats in SVL 
    lsl     x3, x2, #2  // number of floats in VGx4 
    lsl     x4, x3, #2  // number of floats in 4xVGx4 
    
    mov     x5, #0      // base index 
    mov     w8, #0      // za selector 
    mov     w9, #0x7fffffff 
    dup     z20.s, w9 

    udiv    x9, x1, x4  // number of full 4xVGx4 chunks 
    cbz     x9, .L4xVGx4_predicated 

    ptrue   pn8.s 

.L4xVGx4_full:
    add     x6, x5, x3 
    add     x7, x5, x3, lsl #1 
    add     x8, x6, x3, lsl #1 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z4.s-z7.s}, pn8/z, [x0, x6, lsl #2]
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x7, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x8, lsl #2]

    and     z0.s, z0.s, z20.s 
    and     z1.s, z1.s, z20.s
    and     z2.s, z2.s, z20.s 
    and     z3.s, z3.s, z20.s 
    and     z4.s, z4.s, z20.s 
    and     z5.s, z5.s, z20.s 
    and     z6.s, z6.s, z20.s 
    and     z7.s, z7.s, z20.s 
    and     z8.s, z8.s, z20.s 
    and     z9.s, z9.s, z20.s 
    and     z10.s, z10.s, z20.s 
    and     z11.s, z11.s, z20.s 
    and     z12.s, z12.s, z20.s 
    and     z13.s, z13.s, z20.s 
    and     z14.s, z14.s, z20.s 
    and     z15.s, z15.s, z20.s 

    fadd    za.s[w8, #0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, #1, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, #2, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, #3, vgx4], {z12.s-z15.s}

    add     x5, x5, x4 

    subs    x9, x9, #1
    b.ne    .L4xVGx4_full 

.L4xVGx4_predicated:
    add     x6, x5, x3 
    add     x7, x5, x3, lsl #1
    add     x8, x6, x3, lsl #1 

    whilelo pn8.s, x5, x1, vlx4 
    b.none  .L4xVGx4_reduce 

    whilelo pn9.s, x6, x1, vlx4 
    whilelo pn10.s, x7, x1, vlx4
    whilelo pn11.s, x8, x1, vlx4 

    ld1w    {z0.s-z3.s}, pn8/z, [x0, x5, lsl #2]
    ld1w    {z4.s-z7.s}, pn9/z, [x0, x6, lsl #2]
    ld1w    {z8.s-z11.s}, pn10/z, [x0, x7, lsl #2]
    ld1w    {z12.s-z15.s}, pn11/z, [x0, x8, lsl #2]

    and     z0.s, z0.s, z20.s 
    and     z1.s, z1.s, z20.s
    and     z2.s, z2.s, z20.s 
    and     z3.s, z3.s, z20.s 
    and     z4.s, z4.s, z20.s 
    and     z5.s, z5.s, z20.s 
    and     z6.s, z6.s, z20.s 
    and     z7.s, z7.s, z20.s 
    and     z8.s, z8.s, z20.s 
    and     z9.s, z9.s, z20.s 
    and     z10.s, z10.s, z20.s 
    and     z11.s, z11.s, z20.s 
    and     z12.s, z12.s, z20.s 
    and     z13.s, z13.s, z20.s 
    and     z14.s, z14.s, z20.s 
    and     z15.s, z15.s, z20.s 

    fadd    za.s[w8, #0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, #1, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, #2, vgx4], {z8.s-z11.s}
    fadd    za.s[w8, #3, vgx4], {z12.s-z15.s}
    
.L4xVGx4_reduce:
    ptrue   p0.s 

    mova    {z0.s-z3.s}, za.s[w8, #1, vgx4]
    mova    {z4.s-z7.s}, za.s[w8, #2, vgx4]
    mova    {z8.s-z11.s}, za.s[w8, #3, vgx4]

    fadd    za.s[w8, #0, vgx4], {z0.s-z3.s}
    fadd    za.s[w8, #0, vgx4], {z4.s-z7.s}
    fadd    za.s[w8, #0, vgx4], {z8.s-z11.s}

    mova    {z0.s-z3.s}, za.s[w8, #0, vgx4]

    fadd    z0.s, z0.s, z1.s 
    fadd    z2.s, z2.s, z3.s 
    fadd    z0.s, z0.s, z2.s 
    faddv   s0, p0, z0.s 

.L4xVGx4_return:
    fmov    w1, s0 
    smstop 
    fmov    s0, w1 

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 


    


