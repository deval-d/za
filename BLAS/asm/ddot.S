.text
.arch_extension sme-f64f64

.global _ddot 
.p2align 4 

_ddot:
    cmp     w2, #936
    b.lo    _ddot_neon 
    b       _ddot_sme4xVGx4


.global _ddot_neon 
.p2align 4 

_ddot_neon:
    lsr     w3, w2, #3
    and     w4, w2, #7
    lsr     w4, w4, #1
    and     w5, w2, #1

    movi    v0.16b, #0 
    movi    v1.16b, #0 
    movi    v2.16b, #0 
    movi    v3.16b, #0 

    cbz     w2, .Lneon_done 
    cbz     w3, .Lsimd_2 

.Lsimd_8_loop:
    ldp     q4, q5, [x0], #32 
    ldp     q6, q7, [x0], #32 

    ldp     q16, q17, [x1], #32 
    ldp     q18, q19, [x1], #32 

    fmla    v0.2d, v4.2d, v16.2d 
    fmla    v1.2d, v5.2d, v17.2d 
    fmla    v2.2d, v6.2d, v18.2d 
    fmla    v3.2d, v7.2d, v19.2d

    subs    w3, w3, #1 
    b.ne    .Lsimd_8_loop 

.Lsimd_2:
    cbz     w4, .Lneon_reduce 

.Lsimd_2_loop:
    ldr     q4, [x0], #16 
    ldr     q5, [x1], #16 

    fmla    v0.2d, v4.2d, v5.2d 

    subs    w4, w4, #1 
    b.ne    .Lsimd_2 

.Lneon_reduce: 
    fadd    v0.2d, v0.2d, v1.2d 
    fadd    v2.2d, v2.2d, v3.2d 
    fadd    v0.2d, v0.2d, v2.2d 
    faddp   d0, v0.2d

.Lscalar: 
    cbz     x5, .Lneon_done 

.Lscalar_loop:
    ldr     d1, [x0], #8 
    ldr     d2, [x1], #8 

    fmadd   d0, d1, d2, d0 

    subs    w5, w5, #1 
    b.ne    .Lscalar_loop 

.Lneon_done: 
    ret 


.global _ddot_sve 
.p2align 4 

_ddot_sve:
    mov     w2, w2
    sub     sp, sp, #64
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart sm 

    fmov    d0, #0 
    dup     z0.d, z0.d[0]

    mov     w3, #0 
    whilelo p0.d, x3, x2 
    b.none  .Lsve_done

.Lsve_loop:
    ld1d    z1.d, p0/z, [x0]
    ld1d    z2.d, p0/z, [x1] 
    
    fmla    z0.d, p0/m, z1.d, z2.d 

    addvl   x0, x0, #1 
    addvl   x1, x1, #1 

    incd    x3 
    whilelo p0.d, x3, x2 
    b.first .Lsve_loop 

.Lsve_reduce:
    ptrue   p0.d 
    faddv   d0, p0, z0.d 

.Lsve_done:
    fmov    x3, d0 

    smstop  sm 

    fmov    d0, x3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16
    ldp     d14, d15, [sp], #16

    ret 


.global _ddot_sme4xVGx4 
.p2align 4 

_ddot_sme4xVGx4:
    mov     w2, w2
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    // x3 number of doubles in SVL 
    cntd    x3 

    mov     w8, #0 
    
    // base 4xVGx4 group index 
    mov     x12, #0 

    // x5 number of doubles in 16 SVLs
    lsl     x5, x3, #4 

    // number of full 4xVGx4 chunks 
    udiv    x5, x2, x5 
    cbz     x5, .Lsme4_tail_loop

    ptrue   pn8.d 

.Lsme4_full_loop:
    add     x13, x12, x3, lsl #2 
    add     x14, x13, x3, lsl #2 
    add     x15, x14, x3, lsl #2 

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x12, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x13, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x14, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x15, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x12, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x13, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x14, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x15, lsl #3]

    fmla    za.d[w8, 0, vgx4], {z0.d-z3.d}, {z16.d-z19.d}
    fmla    za.d[w8, 1, vgx4], {z4.d-z7.d}, {z20.d-z23.d}
    fmla    za.d[w8, 2, vgx4], {z8.d-z11.d}, {z24.d-z27.d}
    fmla    za.d[w8, 3, vgx4], {z12.d-z15.d}, {z28.d-z31.d}

    incd    x12, all, mul #16
    subs    x5, x5, #1 
    b.ne    .Lsme4_full_loop

.Lsme4_tail_loop:
    add     x13, x12, x3, lsl #2 
    add     x14, x13, x3, lsl #2 
    add     x15, x14, x3, lsl #2 

    whilelo pn8.d, x12, x2, vlx4 
    b.none  .Lsme4_reduce 

    whilelo pn9.d, x13, x2, vlx4
    whilelo pn10.d, x14, x2, vlx4 
    whilelo pn11.d, x15, x2, vlx4

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x12, lsl #3]
    ld1d    {z4.d-z7.d}, pn9/z, [x0, x13, lsl #3]
    ld1d    {z8.d-z11.d}, pn10/z, [x0, x14, lsl #3]
    ld1d    {z12.d-z15.d}, pn11/z, [x0, x15, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x12, lsl #3]
    ld1d    {z20.d-z23.d}, pn9/z, [x1, x13, lsl #3]
    ld1d    {z24.d-z27.d}, pn10/z, [x1, x14, lsl #3]
    ld1d    {z28.d-z31.d}, pn11/z, [x1, x15, lsl #3]

    fmla    za.d[w8, 0, vgx4], {z0.d-z3.d}, {z16.d-z19.d}
    fmla    za.d[w8, 1, vgx4], {z4.d-z7.d}, {z20.d-z23.d}
    fmla    za.d[w8, 2, vgx4], {z8.d-z11.d}, {z24.d-z27.d}
    fmla    za.d[w8, 3, vgx4], {z12.d-z15.d}, {z28.d-z31.d}

    incd    x12, all, mul #16 
    b       .Lsme4_tail_loop 

.Lsme4_reduce:
    mov     {z0.d-z3.d}, za.d[w8, 1, vgx4]
    mov     {z4.d-z7.d}, za.d[w8, 3, vgx4]
    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w8, 2, vgx4], {z4.d-z7.d}

    mov     {z0.d-z3.d}, za.d[w8, 2, vgx4]
    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}

    mov     {z0.d-z3.d}, za.d[w8, 0, vgx4]

    fadd    z0.d, z0.d, z1.d 
    fadd    z2.d, z2.d, z3.d 
    
    fadd    z0.d, z0.d, z2.d 

    ptrue   p0.d 
    faddv   d0, p0, z0.d

.Lsme4_done:
    fmov    x3, d0 

    smstop 

    fmov    d0, x3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
    

.global _ddot_sme8xVGx4
.p2align 4 

_ddot_sme8xVGx4:
    mov     w2, w2
    sub     sp, sp, #64 
    stp     d8, d9, [sp]
    stp     d10, d11, [sp, #16] 
    stp     d12, d13, [sp, #32]
    stp     d14, d15, [sp, #48]

    smstart 
    zero    {za} 

    cntd    x3 

    mov     w8, #0 
    lsr     w9, w3, #1 

    // base 8xVGx4 group index 
    mov     x4, #0 

    // how man double64's in 32 SVL's (8xVGx4)
    lsl     x14, x3, #5 

    // number of full 8xVGx4 chunks 
    udiv    x14, x2, x14
    cbz     x14, .Lsme8_tail_loop 

    ptrue   pn8.d 

.Lsme8_full_loop:
    add     x5, x4, x3, lsl #2 
    add     x6, x5, x3, lsl #2 
    add     x7, x6, x3, lsl #2 
    add     x10, x7, x3, lsl #2 
    add     x11, x10, x3, lsl #2 
    add     x12, x11, x3, lsl #2 
    add     x13, x12, x3, lsl #2

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x4, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x6, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x7, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x4, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x5, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x6, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x7, lsl #3]

    fmla    za.d[w8, 0, vgx4], {z0.d-z3.d}, {z16.d-z19.d}
    fmla    za.d[w8, 1, vgx4], {z4.d-z7.d}, {z20.d-z23.d}
    fmla    za.d[w8, 2, vgx4], {z8.d-z11.d}, {z24.d-z27.d}
    fmla    za.d[w8, 3, vgx4], {z12.d-z15.d}, {z28.d-z31.d} 

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x10, lsl #3]
    ld1d    {z4.d-z7.d}, pn8/z, [x0, x11, lsl #3]
    ld1d    {z8.d-z11.d}, pn8/z, [x0, x12, lsl #3]
    ld1d    {z12.d-z15.d}, pn8/z, [x0, x13, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x10, lsl #3]
    ld1d    {z20.d-z23.d}, pn8/z, [x1, x11, lsl #3]
    ld1d    {z24.d-z27.d}, pn8/z, [x1, x12, lsl #3]
    ld1d    {z28.d-z31.d}, pn8/z, [x1, x13, lsl #3]

    fmla    za.d[w9, 0, vgx4], {z0.d-z3.d}, {z16.d-z19.d}
    fmla    za.d[w9, 1, vgx4], {z4.d-z7.d}, {z20.d-z23.d}
    fmla    za.d[w9, 2, vgx4], {z8.d-z11.d}, {z24.d-z27.d}
    fmla    za.d[w9, 3, vgx4], {z12.d-z15.d}, {z28.d-z31.d}

    incd    x4, all, mul #16 
    incd    x4, all, mul #16 

    subs    x14, x14, #1 
    b.ne    .Lsme8_full_loop 

.Lsme8_tail_loop:
    add     x5, x4, x3, lsl #2 
    add     x6, x5, x3, lsl #2 
    add     x7, x6, x3, lsl #2 

    whilelo pn8.d, x4, x2, vlx4 
    b.none  .Lsme8_reduce 

    whilelo pn9.d, x5, x2, vlx4 
    whilelo pn10.d, x6, x2, vlx4 
    whilelo pn11.d, x7, x2, vlx4 

    ld1d    {z0.d-z3.d}, pn8/z, [x0, x4, lsl #3]
    ld1d    {z4.d-z7.d}, pn9/z, [x0, x5, lsl #3]
    ld1d    {z8.d-z11.d}, pn10/z, [x0, x6, lsl #3]
    ld1d    {z12.d-z15.d}, pn11/z, [x0, x7, lsl #3]

    ld1d    {z16.d-z19.d}, pn8/z, [x1, x4, lsl #3]
    ld1d    {z20.d-z23.d}, pn9/z, [x1, x5, lsl #3]
    ld1d    {z24.d-z27.d}, pn10/z, [x1, x6, lsl #3]
    ld1d    {z28.d-z31.d}, pn11/z, [x1, x7, lsl #3]

    fmla    za.d[w8, 0, vgx4], {z0.d-z3.d}, {z16.d-z19.d}
    fmla    za.d[w8, 1, vgx4], {z4.d-z7.d}, {z20.d-z23.d}
    fmla    za.d[w8, 2, vgx4], {z8.d-z11.d}, {z24.d-z27.d}
    fmla    za.d[w8, 3, vgx4], {z12.d-z15.d}, {z28.d-z31.d}

    incd    x4, all, mul #16 
    b       .Lsme8_tail_loop 

.Lsme8_reduce:
    mov     {z0.d-z3.d}, za.d[w8, 1, vgx4]
    mov     {z4.d-z7.d}, za.d[w8, 3, vgx4]
    mov     {z8.d-z11.d}, za.d[w9, 1, vgx4]
    mov     {z12.d-z15.d}, za.d[w9, 3, vgx4]

    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w8, 2, vgx4], {z4.d-z7.d}
    fadd    za.d[w9, 0, vgx4], {z8.d-z11.d}
    fadd    za.d[w9, 2, vgx4], {z12.d-z15.d}

    mov     {z0.d-z3.d}, za.d[w8, 2, vgx4]
    mov     {z4.d-z7.d}, za.d[w9, 2, vgx4]
    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}
    fadd    za.d[w9, 0, vgx4], {z4.d-z7.d}

    mov     {z0.d-z3.d}, za.d[w9, 0, vgx4]
    fadd    za.d[w8, 0, vgx4], {z0.d-z3.d}

    mov     {z0.d-z3.d}, za.d[w8, 0, vgx4]
    fadd    z0.d, z0.d, z1.d
    fadd    z2.d, z2.d, z3.d
    fadd    z0.d, z0.d, z2.d

    ptrue   p0.d
    faddv   d0, p0, z0.d

.Lsme8_done:
    fmov    x3, d0 

    smstop 

    fmov    d0, x3 

    ldp     d8, d9, [sp], #16 
    ldp     d10, d11, [sp], #16 
    ldp     d12, d13, [sp], #16 
    ldp     d14, d15, [sp], #16 

    ret 
 
