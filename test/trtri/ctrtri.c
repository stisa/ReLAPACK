#include "../../config.h"
#include "../../src/lapack.h"
#include "../test_config.h"
#include "../util.h"
#include "LAPACK_ORIG_trtri.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[]) {

	const int n = TEST_N;
		
	float *A1 = malloc(2 * n * n * sizeof(float));
	float *A2 = malloc(2 * n * n * sizeof(float));

    int info;

    // Lower
    {
        // generate matrix
        c2matgen(n, n, A1, A2);

        // run
        LAPACK(ctrtri)("L", "N", &n, A1, &n, &info);
        LAPACK_ORIG(ctrtri)("L", "N", &n, A2, &n, &info);

        // check error
        float error = c2vecerr(n * n, A1, A2);
        printf("ctrtri Lower:\t%g\n", error);
    }

    // Upper
    {
        // generate matrix
        c2matgen(n, n, A1, A2);

        // run
        LAPACK(ctrtri)("U", "N", &n, A1, &n, &info);
        LAPACK_ORIG(ctrtri)("U", "N", &n, A2, &n, &info);

        // check error
        float error = c2vecerr(n * n, A1, A2);
        printf("ctrtri Upper:\t%g\n", error);
    }

    free(A1); 
    free(A2);

	return 0;
}
