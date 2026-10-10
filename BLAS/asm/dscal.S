.text
.arch_extension sme-f64f64

.global _dscal 
.p2align 4 

_dscal: 
    cmp     w1, #456
    b.lo    _dscal_neon 

    rdsvl   x9, #1 
    cmp     x9, #32 
    b.lo    _dscal_sme4xVGx4 
    b       _dscal_sme8xVGx4 


.global _dscal_neon
.p2align 4

_dscal_neon:
    cbz     w1, .Lneon_done 

    lsr     w2, w1, #3
    and     w3, w1, #7
    lsr     w3, w3, #1
    and     w4, w1, #1

    cbz     w2, .Lsimd_2 

.Lsimd_8_loop: 
    ldp     q1, q2, [x0]
    ldp     q3, q4, [x0, #32]

    fmul    v1.2d, v1.2d, v0.d[0]
    fmul    v2.2d, v2.2d, v0.d[0]
    fmul    v3.2d, v3.2d, v0.d[0]
    fmul    v4.2d, v4.2d, v0.d[0]

    stp     q1, q2, [x0], #32
    stp     q3, q4, [x0], #32 

    subs    w2, w2, #1 
    b.ne    .Lsimd_8_loop 

.Lsimd_2:
    cbz     w3, .Lneon_scalar 

.Lsimd_2_loop:
    ldr     q1, [x0] 
    fmul    v1.2d, v1.2d, v0.d[0]
    str     q1, [x0], #16 

    subs    w3, w3, #1
    b.ne    .Lsimd_2_loop 

.Lneon_scalar:
    cbz     w4, .Lneon_done 

.Lneon_scalar_loop:
    ldr     d1, [x0]
    fmul    d1, d1, d0 
    str     d1, [x0], #8 

    subs    w4, w4, #1
    b.ne    .Lneon_scalar_loop 

.Lneon_done:
    ret


.global _dscal_sve 
.p2align 4 

_dscal_sve:
    mov     w1, w1
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x2, d0 

    smstart sm 

    fmov    d0, x2 
    dup     z0.d, z0.d[0]

    mov     w3, #0 
    whilelo p0.d, x3, x1
    b.none  .Lsve_done 

.Lsve_loop:
    ld1d    z1.d, p0/z, [x0]
    fmul    z1.d, p0/m, z1.d, z0.d
    st1d    z1.d, p0, [x0]

    addvl   x0, x0, #1 

    incd    x3 
    whilelo p0.d, x3, x1 
    b.first .Lsve_loop

.Lsve_done:
    smstop  sm 
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _dscal_sme4xVGx4
.p2align 4 

_dscal_sme4xVGx4:
    mov     w1, w1
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x2, d0 

    smstart
    zero    {za}

    fmov    d0, x2 
    dup     z0.d, z0.d[0]

    cntd    x4 
    
    mov     w8, #0 

    // base 4xVGx4 group index 
    mov     x5, #0 

    // how many float64's in 16 SVL's (4xVGx4)
    lsl     x13, x4, #4 

    // number of full 4xVGx4 chunks 
    udiv    x13, x1, x13 
    cbz     x13, .Lsme4_tail_loop

    ptrue   pn8.d 

.Lsme4_full_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x6, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn8/z, [x0, x14, lsl #3] 

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z0.d 
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z0.d 
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z0.d 
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z0.d 

    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4] 
    mov     {z8.d-z11.d}, za.d[w8, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w8, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w8, 3, vgx4] 

    st1d    {z4.d-z7.d}, pn8, [x0, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x0, x6, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x0, x7, lsl #3]
    st1d    {z16.d-z19.d}, pn8, [x0, x14, lsl #3] 

    zero    {za}
    incd    x5, all, mul #16 
    subs    x13, x13, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.d, x5, x1, vlx4 
    b.none  .Lsme4_done 

    whilelo pn9.d, x6, x1, vlx4 
    whilelo pn10.d, x7, x1, vlx4 
    whilelo pn11.d, x14, x1, vlx4 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn9/z, [x0, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn10/z, [x0, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn11/z, [x0, x14, lsl #3] 

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z0.d 
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z0.d
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z0.d 
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z0.d 

    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    mov     {z8.d-z11.d}, za.d[w8, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w8, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w8, 3, vgx4] 

    st1d    {z4.d-z7.d}, pn8, [x0, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn9, [x0, x6, lsl #3] 
    st1d    {z12.d-z15.d}, pn10, [x0, x7, lsl #3]
    st1d    {z16.d-z19.d}, pn11, [x0, x14, lsl #3]

    zero    {za}
    incd    x5, all, mul #16 
    b       .Lsme4_tail_loop 

.Lsme4_done: 
    smstop
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret


.global _dscal_sme8xVGx4
.p2align 4 

_dscal_sme8xVGx4:
    mov     w1, w1
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x2, d0 

    smstart 
    zero    {za} 

    fmov    d0, x2 
    dup     z0.d, z0.d[0]

    cntd    x4 
    
    mov     w8, #0 
    lsr     w9, w4, #1 

    // base 8xVGx4 group index 
    mov     x5, #0 

    // how many float64's in 32 SVL's (8xVGx4)
    lsl     x13, x4, #5 

    // number of full 8xVGx4 chunks 
    udiv    x13, x1, x13
    cbz     x13, .Lsme8_tail_loop

    ptrue   pn8.d 

.Lsme8_full_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 
    add     x15, x14, x4, lsl #2 
    add     x10, x15, x4, lsl #2 
    add     x11, x10, x4, lsl #2 
    add     x12, x11, x4, lsl #2 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x6, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn8/z, [x0, x14, lsl #3] 

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z0.d 
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z0.d 
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z0.d 
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z0.d 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x15, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x10, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x11, lsl #3]
    ld1d    {z16.d-z19.d}, pn8/z, [x0, x12, lsl #3] 

    fmla    za.d[w9, 0, vgx4], {z4.d-z7.d}, z0.d
    fmla    za.d[w9, 1, vgx4], {z8.d-z11.d}, z0.d
    fmla    za.d[w9, 2, vgx4], {z12.d-z15.d}, z0.d
    fmla    za.d[w9, 3, vgx4], {z16.d-z19.d}, z0.d 

    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4] 
    mov     {z8.d-z11.d}, za.d[w8, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w8, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w8, 3, vgx4] 

    st1d    {z4.d-z7.d}, pn8, [x0, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x0, x6, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x0, x7, lsl #3]
    st1d    {z16.d-z19.d}, pn8, [x0, x14, lsl #3] 

    mov     {z4.d-z7.d}, za.d[w9, 0, vgx4] 
    mov     {z8.d-z11.d}, za.d[w9, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w9, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w9, 3, vgx4] 

    st1d    {z4.d-z7.d}, pn8, [x0, x15, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x0, x10, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x0, x11, lsl #3]
    st1d    {z16.d-z19.d}, pn8, [x0, x12, lsl #3] 

    zero    {za}
    incd    x5, all, mul #16 
    incd    x5, all, mul #16 
    subs    x13, x13, #1 
    b.ne    .Lsme8_full_loop

.Lsme8_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.d, x5, x1, vlx4 
    b.none  .Lsme8_done 

    whilelo pn9.d, x6, x1, vlx4 
    whilelo pn10.d, x7, x1, vlx4 
    whilelo pn11.d, x14, x1, vlx4 

    ld1d    {z4.d-z7.d}, pn8/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn9/z, [x0, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn10/z, [x0, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn11/z, [x0, x14, lsl #3] 

    fmla    za.d[w8, 0, vgx4], {z4.d-z7.d}, z0.d
    fmla    za.d[w8, 1, vgx4], {z8.d-z11.d}, z0.d
    fmla    za.d[w8, 2, vgx4], {z12.d-z15.d}, z0.d
    fmla    za.d[w8, 3, vgx4], {z16.d-z19.d}, z0.d

    mov     {z4.d-z7.d}, za.d[w8, 0, vgx4]
    mov     {z8.d-z11.d}, za.d[w8, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w8, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w8, 3, vgx4]

    st1d    {z4.d-z7.d}, pn8, [x0, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn9, [x0, x6, lsl #3] 
    st1d    {z12.d-z15.d}, pn10, [x0, x7, lsl #3]
    st1d    {z16.d-z19.d}, pn11, [x0, x14, lsl #3]

    zero    {za}
    incd    x5, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_done: 
    smstop
    
    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret

  

    
    
 
