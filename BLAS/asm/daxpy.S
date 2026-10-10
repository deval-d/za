.text
.arch_extension sme-f64f64

.global _daxpy 
.p2align 4 

_daxpy:
    cmp     w2, #360
    b.lo    _daxpy_neon 
    b       _daxpy_sme4xVGx4


.global _daxpy_neon
.p2align 4 

_daxpy_neon:
    cbz     w2, .Lneon_done 

    lsr     w3, w2, #3
    and     w4, w2, #7
    lsr     w4, w4, #1
    and     w5, w2, #1

    cbz     w3, .Lsimd_2 

.Lsimd_8_loop:
    ldp     q1, q2, [x0], #32 
    ldp     q3, q4, [x0], #32 
    ldp     q16, q17, [x1] 
    ldp     q18, q19, [x1, #32]

    fmla    v16.2d, v1.2d, v0.d[0]
    fmla    v17.2d, v2.2d, v0.d[0]
    fmla    v18.2d, v3.2d, v0.d[0]
    fmla    v19.2d, v4.2d, v0.d[0]

    stp     q16, q17, [x1], #32
    stp     q18, q19, [x1], #32

    subs    w3, w3, #1
    b.ne    .Lsimd_8_loop 

.Lsimd_2: 
    cbz     w4, .Lneon_scalar 

.Lsimd_2_loop:
    ldr     q1, [x0], #16 
    ldr     q2, [x1] 

    fmla    v2.2d, v1.2d, v0.d[0]
     
    str     q2, [x1], #16 

    subs    w4, w4, #1 
    b.ne    .Lsimd_2_loop 

.Lneon_scalar: 
    cbz     w5, .Lneon_done 

.Lneon_scalar_loop:
    ldr     d1, [x0], #8 
    ldr     d2, [x1]

    fmadd   d2, d0, d1, d2 

    str     d2, [x1], #8 

    subs    w5, w5, #1 
    b.ne    .Lneon_scalar_loop 

.Lneon_done: 
    ret 
   

.global _daxpy_sve 
.p2align 4 

_daxpy_sve:
    mov     w2, w2
    sub     sp, sp, #64 
    stp     d8, d9, [sp] 
    stp     d10, d11, [sp, #16]
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    fmov    x3, d0 

    smstart sm 

    fmov    d0, x3 
    dup     z0.d, z0.d[0]

    mov     w4, #0 
    whilelo p0.d, x4, x2 
    b.none  .Lsve_done 

.Lsve_loop:
    ld1d    z1.d, p0/z, [x0] 
    ld1d    z2.d, p0/z, [x1] 

    fmla    z2.d, p0/m, z1.d, z0.d 

    st1d    z2.d, p0, [x1]

    addvl   x0, x0, #1 
    addvl   x1, x1, #1 

    incd    x4
    whilelo p0.d, x4, x2 
    b.first .Lsve_loop 

.Lsve_done:
    smstop  sm

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 


.global _daxpy_sme8xVGx4
.p2align 4 

_daxpy_sme8xVGx4:
    mov     w2, w2
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, 16]
    stp     d12, d13, [sp, 32]
    stp     d14, d15, [sp, #48]

    fmov    x3, d0 

    smstart 

    fmov    d0, x3 
    dup     z0.d, z0.d[0]

    cntd    x4  

    mov     w8, #0 
    lsr     w9, w4, #1 

    // base index 
    mov     x5, #0 

    lsl     x13, x4, #5 

    // number of full 8xVGx4 chunks 
    udiv    x13, x2, x13 
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

    ld1d    {z4.d-z7.d}, pn8/z, [x1, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x1, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn8/z, [x1, x7, lsl #3] 
    ld1d    {z16.d-z19.d}, pn8/z, [x1, x14, lsl #3]
    
    mov     za.d[w8, 0, vgx4], {z4.d-z7.d}
    mov     za.d[w8, 1, vgx4], {z8.d-z11.d}
    mov     za.d[w8, 2, vgx4], {z12.d-z15.d}
    mov     za.d[w8, 3, vgx4], {z16.d-z19.d} 

    ld1d    {z4.d-z7.d}, pn8/z, [x1, x15, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x1, x10, lsl #3] 
    ld1d    {z12.d-z15.d}, pn8/z, [x1, x11, lsl #3] 
    ld1d    {z16.d-z19.d}, pn8/z, [x1, x12, lsl #3]
    
    mov     za.d[w9, 0, vgx4], {z4.d-z7.d}
    mov     za.d[w9, 1, vgx4], {z8.d-z11.d}
    mov     za.d[w9, 2, vgx4], {z12.d-z15.d}
    mov     za.d[w9, 3, vgx4], {z16.d-z19.d} 

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

    st1d    {z4.d-z7.d}, pn8, [x1, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x6, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x7, lsl #3] 
    st1d    {z16.d-z19.d}, pn8, [x1, x14, lsl #3] 

    mov     {z4.d-z7.d}, za.d[w9, 0, vgx4]
    mov     {z8.d-z11.d}, za.d[w9, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w9, 2, vgx4]
    mov     {z16.d-z19.d}, za.d[w9, 3, vgx4] 

    st1d    {z4.d-z7.d}, pn8, [x1, x15, lsl #3]
    st1d    {z8.d-z11.d}, pn8, [x1, x10, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x11, lsl #3] 
    st1d    {z16.d-z19.d}, pn8, [x1, x12, lsl #3]
     
    incd    x5, all, mul #16 
    incd    x5, all, mul #16

    subs    x13, x13, #1 
    b.ne    .Lsme8_full_loop 

.Lsme8_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.d, x5, x2, vlx4 
    b.none  .Lsme8_done 

    whilelo pn9.d, x6, x2, vlx4
    whilelo pn10.d, x7, x2, vlx4 
    whilelo pn11.d, x14, x2, vlx4 

    ld1d    {z4.d-z7.d}, pn8/z, [x1, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn9/z, [x1, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn10/z, [x1, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn11/z, [x1, x14, lsl #3] 

    mov     za.d[w8, 0, vgx4], {z4.d-z7.d}
    mov     za.d[w8, 1, vgx4], {z8.d-z11.d}
    mov     za.d[w8, 2, vgx4], {z12.d-z15.d}
    mov     za.d[w8, 3, vgx4], {z16.d-z19.d}

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

    st1d    {z4.d-z7.d}, pn8, [x1, x5, lsl #3]
    st1d    {z8.d-z11.d}, pn9, [x1, x6, lsl #3] 
    st1d    {z12.d-z15.d}, pn10, [x1, x7, lsl #3]
    st1d    {z16.d-z19.d}, pn11, [x1, x14, lsl #3]

    incd    x5, all, mul #16 
    b       .Lsme8_tail_loop

.Lsme8_done:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16 

    ret


.global _daxpy_sme4xVGx4 
.p2align 4 

_daxpy_sme4xVGx4: 
    mov     w2, w2
    sub     sp, sp, #64
    stp     d8, d9, [sp] 
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48] 

    fmov    x3, d0 

    smstart 

    fmov    d0, x3 
    dup     z0.d, z0.d[0] 

    cntd    x4  

    mov     w8, #0 

    // base index 
    mov     x5, #0 

    lsl     x13, x4, #4

    // number of full 4xVGx4 chunks 
    udiv    x13, x2, x13 
    cbz     x13, .Lsme4_tail_loop

    ptrue   pn8.d 

.Lsme4_full_loop:
    add     x6, x5, x4, lsl #2
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    ld1d    {z4.d-z7.d}, pn8/z, [x1, x5, lsl #3] 
    ld1d    {z8.d-z11.d}, pn8/z, [x1, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn8/z, [x1, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn8/z, [x1, x14, lsl #3]

    mov     za.d[w8, 0, vgx4], {z4.d-z7.d}
    mov     za.d[w8, 1, vgx4], {z8.d-z11.d}
    mov     za.d[w8, 2, vgx4], {z12.d-z15.d}
    mov     za.d[w8, 3, vgx4], {z16.d-z19.d} 

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

    st1d    {z4.d-z7.d}, pn8, [x1, x5, lsl #3] 
    st1d    {z8.d-z11.d}, pn8, [x1, x6, lsl #3]
    st1d    {z12.d-z15.d}, pn8, [x1, x7, lsl #3] 
    st1d    {z16.d-z19.d}, pn8, [x1, x14, lsl #3]

    incd    x5, all, mul #16 
    subs    x13, x13, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x6, x5, x4, lsl #2 
    add     x7, x6, x4, lsl #2 
    add     x14, x7, x4, lsl #2 

    whilelo pn8.d, x5, x2, vlx4
    b.none  .Lsme4_done 

    whilelo pn9.d, x6, x2, vlx4
    whilelo pn10.d, x7, x2, vlx4 
    whilelo pn11.d, x14, x2, vlx4

    ld1d    {z4.d-z7.d}, pn8/z, [x1, x5, lsl #3] 
    ld1d    {z8.d-z11.d}, pn9/z, [x1, x6, lsl #3] 
    ld1d    {z12.d-z15.d}, pn10/z, [x1, x7, lsl #3]
    ld1d    {z16.d-z19.d}, pn11/z, [x1, x14, lsl #3]

    mov     za.d[w8, 0, vgx4], {z4.d-z7.d}
    mov     za.d[w8, 1, vgx4], {z8.d-z11.d}
    mov     za.d[w8, 2, vgx4], {z12.d-z15.d}
    mov     za.d[w8, 3, vgx4], {z16.d-z19.d} 

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

    st1d    {z4.d-z7.d}, pn8, [x1, x5, lsl #3] 
    st1d    {z8.d-z11.d}, pn9, [x1, x6, lsl #3]
    st1d    {z12.d-z15.d}, pn10, [x1, x7, lsl #3] 
    st1d    {z16.d-z19.d}, pn11, [x1, x14, lsl #3]

    incd    x5, all, mul #16 
    b       .Lsme4_tail_loop 

.Lsme4_done:
    smstop 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret  
