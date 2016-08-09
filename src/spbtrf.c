#include "relapack.h"
#include "stdlib.h"

static void RELAPACK_spbtrf_rec(const char *, const int *, const int *,
    float *, const int *, float *, const int *, int *);


/** SPBTRF computes the Cholesky factorization of a real symmetric positive definite band matrix A.
 *
 * This routine is functionally equivalent to LAPACK's spbtrf.
 * For details on its interface, see
 * http://www.netlib.org/lapack/explore-html/d1/d22/spbtrf_8f.html
 * */
void RELAPACK_spbtrf(
    const char *uplo, const int *n, const int *kd,
    float *Ab, const int *ldAb,
    int *info
) {

    // Check arguments
    const int lower = LAPACK(lsame)(uplo, "L");
    const int upper = LAPACK(lsame)(uplo, "U");
    *info = 0;
    if (!lower && !upper)
        *info = -1;
    else if (*n < 0)
        *info = -2;
    else if (*kd < 0)
        *info = -3;
    else if (*ldAb < *kd + 1)
        *info = -5;
    if (*info) {
        const int minfo = -*info;
        LAPACK(xerbla)("SPBTRF", &minfo);
        return;
    }

    // Clean char * arguments
    const char cleanuplo = lower ? 'L' : 'U';

    const float ZERO[] = { 0. };
    const int nW = REC_SPLIT(*n) + 8;
    float *W = malloc(nW * nW * sizeof(float));
    LAPACK(slaset)("G", &nW, &nW, ZERO, ZERO, W, &nW);

    RELAPACK_spbtrf_rec(&cleanuplo, n, kd, Ab, ldAb, W, &nW, info);

    free(W);
}


/** spbtrf's recursive compute kernel */
static void RELAPACK_spbtrf_rec(
    const char *uplo, const int *n, const int *kd,
    float *Ab, const int *ldAb,
    float *W, const int *ldW,
    int *info
){

    if (*n <= MAX(CROSSOVER_SPBTRF, 1)) {
        // Unblocked
        LAPACK(spbtf2)(uplo, n, kd, Ab, ldAb, info);
        return;
    }

    // Constants
    const float ONE[]  = { 1. };
    const float MONE[] = { -1. };

    // Splitting
    const int n1 = REC_SPLIT(*n);
    const int n2 = *n - n1;

    // Ab_TL *
    // *     Ab_BR
    float *const Ab_TL = Ab;
    float *const Ab_BR = Ab + *ldAb * n1;

    // Unskewing A
    const int ldA[] = { *ldAb - 1 };
    float *const A = Ab + ((*uplo == 'L') ? 0 : *kd);

    // A_TL A_TR
    // A_BL A_BR
    float *const A_TL = A;
    float *const A_TR = A + *ldA * n1;
    float *const A_BL = A             + n1;
    float *const A_BR = A + *ldA * n1 + n1;

    // recursion(A_TL)
    RELAPACK_spbtrf_rec(uplo, &n1, kd, Ab_TL, ldAb, W, ldW, info);

    if (*kd > n1) {  // Band is larger than n1
        // Banded splitting
        const int n21 = MIN(n2, *kd - n1);
        const int n22 = n2 - n21;

        //     n1    n21    n22
        // n1  *     A_TRl  A_TRr
        // n21 A_BLt A_BRtl A_BRtr
        // n22 A_BLb A_BRbl A_BRbr
        float *const A_TRl  = A_TR;
        float *const A_TRr  = A_TR + *ldA * n21;
        float *const A_BLt  = A_BL;
        float *const A_BLb  = A_BL               + n21;
        float *const A_BRtl = A_BR;
        float *const A_BRtr = A_BR + *ldA * n21;
        float *const A_BRbl = A_BR               + n21;
        float *const A_BRbr = A_BR + *ldA * n21  + n21;

        if (*uplo == 'L') {
            // A_BLt = ABLt / A_TL'
            BLAS(strsm)("R", "L", "T", "N", &n21, &n1, ONE, A_TL, ldA, A_BLt, ldA);
            // A_BRtl = A_BRtl - A_BLt * A_BLt'
            BLAS(ssyrk)("L", "N", &n21, &n1, MONE, A_BLt, ldA, ONE, A_BRtl, ldA);
            // W = A_BLb
            LAPACK(slacpy)("U", &n22, &n1, A_BLb, ldA, W, ldW);
            // W = W / A_TL'
            BLAS(strsm)("R", "L", "T", "N", &n22, &n1, ONE, A_TL, ldA, W, ldW);
            // A_BRbl = A_BRbl - W * A_BLt'
            BLAS(sgemm)("N", "T", &n22, &n21, &n1, MONE, W, ldW, A_BLt, ldA, ONE, A_BRbl, ldA);
            // A_BRbr = A_BRbr - W * W'
            BLAS(ssyrk)("L", "N", &n22, &n1, MONE, W, ldW, ONE, A_BRbr, ldA);
            // A_BLb = W
            LAPACK(slacpy)("U", &n22, &n1, W, ldW, A_BLb, ldA);
        } else {
            // A_TRl = A_TL' \ A_TRl
            BLAS(strsm)("L", "U", "T", "N", &n1, &n21, ONE, A_TL, ldA, A_TRl, ldA);
            // A_BRtl = A_BRtl - A_TRl' * A_TRl
            BLAS(ssyrk)("U", "T", &n21, &n1, MONE, A_TRl, ldA, ONE, A_BRtl, ldA);
            // W = A_TRr
            LAPACK(slacpy)("L", &n1, &n22, A_TRr, ldA, W, ldW);
            // W = A_TL' \ W
            BLAS(strsm)("L", "U", "T", "N", &n1, &n22, ONE, A_TL, ldA, W, ldW);
            // A_BRtr = A_BRtr - A_TRl' * W
            BLAS(sgemm)("T", "N", &n21, &n22, &n1, MONE, A_TRl, ldA, W, ldW, ONE, A_BRtr, ldA);
            // A_BRbr = A_BRbr - W' * W
            BLAS(ssyrk)("U", "T", &n22, &n1, MONE, W, ldW, ONE, A_BRbr, ldA);
            // A_TRr = W
            LAPACK(slacpy)("L", &n1, &n22, W, ldW, A_TRr, ldA);
        }
    } else {  // Band is smaller than n1
        // Banded splitting
        const int n11 = n1 - *kd;

        //     n11 kd     kd
        // n11 *   *      0      0
        // kd  *   A_TLbr A_TRbl 0
        // kd  0   A_BLtr A_BRtl *
        //     0   0      *      *
        float *const A_TLbr = A_TL + *ldA * n11 + n11;
        float *const A_TRbl = A_TR              + n11;
        float *const A_BLtr = A_BL + *ldA * n11;
        float *const A_BRtl = A_BR;

        if (*uplo == 'L') {
            // W = A_BLtr
            LAPACK(slacpy)("U", kd, kd, A_BLtr, ldA, W, ldW);
            // W = W / A_TLbr'
            BLAS(strsm)("R", "L", "T", "N", kd, kd, ONE, A_TLbr, ldA, W, ldW);
            // A_BRtl = A_BRtl - W * W'
            BLAS(ssyrk)("L", "N", kd, kd, MONE, W, ldW, ONE, A_BRtl, ldA);
            // A_BLtr = W
            LAPACK(slacpy)("U", kd, kd, W, ldW, A_BLtr, ldA);
        } else {
            // W = A_TRbl
            LAPACK(slacpy)("L", kd, kd, A_TRbl, ldA, W, ldW);
            // W = A_TLbr' \ W
            BLAS(strsm)("L", "U", "T", "N", kd, kd, ONE, A_TLbr, ldA, W, ldW);
            // A_BRtl = A_BRtl - W' * W
            BLAS(ssyrk)("U", "T", kd, kd, MONE, W, ldW, ONE, A_BRtl, ldA);
            // A_TRbl = W
            LAPACK(slacpy)("L", kd, kd, W, ldW, A_TRbl, ldA);
        }
    }

    // recursion(A_BR)
    RELAPACK_spbtrf_rec(uplo, &n2, kd, Ab_BR, ldAb, W, ldW, info);
    if (*info)
        *info += n1;
}
