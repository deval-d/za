.text

.global _sscal_asm
.p2align 4 

_sscal_asm:
    cmp     x1, #752
    b.lo    _sscal_neon 
    
    rdsvl   x14, #1 
    cmp     x14, #32
    b.lo    _sscal_sme4xVGx4
    b       _sscal_sme8xVGx4        


.global _sscal_neon
.p2align 4 

_sscal_neon:
    lsr     x2, x1, #5 
    and     x3, x1, #31 
    lsr     x3, x3, #4
    and     x4, x1, #15
    lsr     x4, x4, #2
    and     x5, x1, #3 

    cbz     x2, .Lsimd_16 

.Lsimd_32_loop:
    ldp     q1, q2, [x0]
    ldp     q3, q4, [x0, #32]
    ldp     q5, q6, [x0, #64]
    ldp     q7, q16, [x0, #96]

    fmul    v1.4s, v1.4s, v0.s[0]
    fmul    v2.4s, v2.4s, v0.s[0]
    fmul    v3.4s, v3.4s, v0.s[0]
    fmul    v4.4s, v4.4s, v0.s[0]
    fmul    v5.4s, v5.4s, v0.s[0]
    fmul    v6.4s, v6.4s, v0.s[0]
    fmul    v7.4s, v7.4s, v0.s[0]
    fmul    v16.4s, v16.4s, v0.s[0] 

    stp     q1, q2, [x0], #32
    stp     q3, q4, [x0], #32
    stp     q5, q6, [x0], #32
    stp     q7, q16, [x0], #32 

    subs    x2, x2, #1
    b.ne    .Lsimd_32_loop 

.Lsimd_16:
    cbz     x3, .Lsimd_4

.Lsimd_16_loop:
    ldp     q1, q2, [x0]
    ldp     q3, q4, [x0, #32]

    fmul    v1.4s, v1.4s, v0.s[0]
    fmul    v2.4s, v2.4s, v0.s[0]
    fmul    v3.4s, v3.4s, v0.s[0]
    fmul    v4.4s, v4.4s, v0.s[0]

    stp     q1, q2, [x0], #32
    stp     q3, q4, [x0], #32 

    subs    x3, x3, #1
    b.ne    .Lsimd_16_loop 

.Lsimd_4:
    cbz     x4, .Lscalar 

.Lsimd_4_loop:
    ldr     q1, [x0]

    fmul    v1.4s, v1.4s, v0.s[0]

    str     q1, [x0], #16 

    subs    x4, x4, #1
    b.ne    .Lsimd_4_loop

.Lscalar:
    cbz     x5, .Lneon_return 

.Lscalar_loop:
    ldr     s1, [x0]

    fmul    s1, s1, s0 
    
    str     s1, [x0], #4 

    subs    x5, x5, #1
    b.ne    .Lscalar_loop 

.Lneon_return:
    ret


.global _sscal_sme4xVGx4
.p2align 4 

_sscal_sme4xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0

    smstart 

    fmov    s0, w3 
    dup     z0.s, z0.s[0]

    cntw    x3
    lsl     x4, x3, #2 
    lsl     x5, x4, #2 

    mov     x7, #0 
    mov     w11, #0 

    udiv    x6, x1, x5 
    cbz     x6, .L4xVGx4_predicated 

    ptrue pn8.s 

.L4xVGx4_full:
    zero    {za}

    add     x8, x7, x4 
    add     x9, x7, x4, lsl #1 
    add     x10, x8, x4, lsl #1 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x7, lsl #2] 
    ld1w    {z8.s-z11.s}, pn8/z, [x0, x8, lsl #2]
    ld1w    {z12.s-z15.s}, pn8/z, [x0, x9, lsl #2]
    ld1w    {z16.s-z19.s}, pn8/z, [x0, x10, lsl #2]

    fmla    za.s[w11, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w11, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w11, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w11, #3, vgx4], {z16.s-z19.s}, z0.s 

    mova    {z4.s-z7.s}, za.s[w11, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w11, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w11, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w11, #3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x7, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x8, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x9, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x10, lsl #2]

    add     x7, x7, x5
    subs    x6, x6, #1
    b.ne    .L4xVGx4_full

.L4xVGx4_predicated:
    zero    {za}

    add     x8, x7, x4 
    add     x9, x7, x4, lsl #1
    add     x10, x8, x4, lsl #1

    whilelo pn8.s, x7, x1, vlx4 
    b.none  .L4xVGx4_return 

    whilelo pn9.s, x8, x1, vlx4
    whilelo pn10.s, x9, x1, vlx4
    whilelo pn11.s, x10, x1, vlx4 

    ld1w    {z4.s-z7.s}, pn8/z, [x0, x7, lsl #2] 
    ld1w    {z8.s-z11.s}, pn9/z, [x0, x8, lsl #2]
    ld1w    {z12.s-z15.s}, pn10/z, [x0, x9, lsl #2]
    ld1w    {z16.s-z19.s}, pn11/z, [x0, x10, lsl #2]

    fmla    za.s[w11, #0, vgx4], {z4.s-z7.s}, z0.s 
    fmla    za.s[w11, #1, vgx4], {z8.s-z11.s}, z0.s 
    fmla    za.s[w11, #2, vgx4], {z12.s-z15.s}, z0.s 
    fmla    za.s[w11, #3, vgx4], {z16.s-z19.s}, z0.s 

    mova    {z4.s-z7.s}, za.s[w11, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w11, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w11, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w11, #3, vgx4] 

    st1w    {z4.s-z7.s}, pn8, [x0, x7, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x0, x8, lsl #2]
    st1w    {z12.s-z15.s}, pn10, [x0, x9, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x0, x10, lsl #2]

.L4xVGx4_return:
    smstop 

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret 


.global _sscal_sme8xVGx4
.p2align 4

_sscal_sme8xVGx4:
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    w3, s0

    smstart

    fmov    s0, w3
    dup     z0.s, z0.s[0]

    cntw    x3          
    lsl     x4, x3, #2  
    lsl     x5, x4, #3  

    mov     w8, #0
    mov     x10, #0
    rdsvl   x9, #1
    lsr     x9, x9, #3

    udiv    x6, x1, x5  
    cbz     x6, .L8xVGx4_predicated

    ptrue   pn8.s

.L8xVGx4_full:
    zero    {za}

    add     x11, x10, x4
    add     x12, x10, x4, lsl #1
    add     x13, x11, x4, lsl #1
    add     x14, x10, x4, lsl #2
    add     x15, x11, x4, lsl #2
    add     x16, x12, x4, lsl #2
    add     x17, x13, x4, lsl #2

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

    st1w    {z4.s-z7.s}, pn8, [x0, x10, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x11, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x12, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x13, lsl #2]

    mova    {z4.s-z7.s}, za.s[w9, #0, vgx4]
    mova    {z8.s-z11.s}, za.s[w9, #1, vgx4]
    mova    {z12.s-z15.s}, za.s[w9, #2, vgx4]
    mova    {z16.s-z19.s}, za.s[w9, #3, vgx4]

    st1w    {z4.s-z7.s}, pn8, [x0, x14, lsl #2]
    st1w    {z8.s-z11.s}, pn8, [x0, x15, lsl #2]
    st1w    {z12.s-z15.s}, pn8, [x0, x16, lsl #2]
    st1w    {z16.s-z19.s}, pn8, [x0, x17, lsl #2]

    add     x10, x10, x5
    subs    x6, x6, #1
    b.ne    .L8xVGx4_full

.L8xVGx4_predicated:
    zero    {za}

    add     x11, x10, x4
    add     x12, x10, x4, lsl #1
    add     x13, x11, x4, lsl #1

    whilelo pn8.s, x10, x1, vlx4
    b.none  .L8xVGx4_return

    whilelo pn9.s, x11, x1, vlx4
    whilelo pn10.s, x12, x1, vlx4
    whilelo pn11.s, x13, x1, vlx4

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

    st1w    {z4.s-z7.s}, pn8, [x0, x10, lsl #2]
    st1w    {z8.s-z11.s}, pn9, [x0, x11, lsl #2]
    st1w    {z12.s-z15.s}, pn10, [x0, x12, lsl #2]
    st1w    {z16.s-z19.s}, pn11, [x0, x13, lsl #2]

    add     x10, x10, x4, lsl #2
    b       .L8xVGx4_predicated

.L8xVGx4_return:
    smstop

    ldp     d8, d9, [sp], #16
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret
