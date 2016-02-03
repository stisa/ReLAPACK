#include "../src/relapack.h"
#include "util.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[]) {

    if (argc == 1) {
        fprintf(stderr, "usage: %s n\n", argv[0]);
        return 0;
    }
    const int n = atoi(argv[1]);
		
    const int lWork = n * n;
	double *A1    = malloc(n * n * 2 * sizeof(double));
	double *A2    = malloc(n * n * 2 * sizeof(double));
	int    *ipiv1 = malloc(n * sizeof(int));
	int    *ipiv2 = malloc(n * sizeof(int));
	double *Work  = malloc(lWork * 2 * sizeof(double));

    // Output
    int info;

    { // L
        // generate matrix
        z2matgen(n, n, A1, A2);

        // run
        RELAPACK(zhetrf_rook)("L", &n, A1, &n, ipiv1, Work, &lWork, &info);
        LAPACK(zhetf2_rook)("L", &n, A2, &n, ipiv2, &info);

        // check error
        const double error = z2vecerr(n * n, A1, A2) + i2vecerr(n, ipiv1, ipiv2);
        printf("zhetrf_rook L:\t%g\n", error);
    }

    { // U
        // generate matrix
        z2matgen(n, n, A1, A2);

        // run
        RELAPACK(zhetrf_rook)("U", &n, A1, &n, ipiv1, Work, &lWork, &info);
        LAPACK(zhetf2_rook)("U", &n, A2, &n, ipiv2, &info);

        // check error
        const double error = z2vecerr(n * n, A1, A2) + i2vecerr(n, ipiv1, ipiv2);
        printf("zhetrf_rook U:\t%g\n", error);
    }

    free(A1);
    free(A2);
    free(ipiv1);
    free(ipiv2);
    free(Work);

	return 0;
}