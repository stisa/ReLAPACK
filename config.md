RELAPACK Configuration
======================
ReLAPACK has two configuration files: `make.inc`, which is included by the
Makefile, and `config.h` which is included in the source files.

Build and Testing Environment
-----------------------------
The build environment (compilers and flags) and the test configuration (linker
flags for BLAS and LAPACK, and the test matrix size) are specified in `make.inc`

Routine Selection
-----------------
By default, ReLAPACK provides each of its LAPACK-based recursive algorithms
under two names: 1) with the prefix `RELAPACK_`, e.g., `RELAPACK_dgetrf` and 2)
using LAPACK's routine name, e.g., `dgetrf_`.  The latter of these, which allows
to easily replace LAPACK in existing application, can be disabled on an
operation or routine basis in `config.h`

## Routine Names
By default, ReLAPACK's routine names coincide with the functionally equivalent
LAPACK routines. By setting `RELAPACK_AS_LAPACK` to 0 in `config.h`, they will
receive the prefix `RELAPACK_`; e.g. the LU decomposition `dgetrf` would become
`RELAPACK_dgetrf`.

Crossover Size
--------------
The crossover size determines below which matrix sizes ReLAPACK's recursive
algorithms switch to LAPACK's unblocked routines to avoid tiny BLAS Level 3
routines.  The crossover size is set in `config.h` and can be chosen either
globally for the entire library, by operation, or individually by routine.

Allowing Temporary Buffers
--------------------------
Two of ReLAPACK's routines make use of temporary buffers, which are allocated
and freed within ReLAPACK.  Setting `ALLOW_MALLOC` (or one of the routine
specific counterparts) to 0 in `config.h` will disable these buffers.  The
affected routines are:

 * `xsytrf`: The LDL decomposition requires a buffer of size n^2 / 2.  As in
   LAPACK, this size can be queried by setting `lWork = -1` and the passed
   buffer will be used if it is large enough; only if it is not, a local buffer
   will be allocated.  
   
   The advantage of this mechanism is that ReLAPACK will seamlessly work even
   with codes that statically provide too little memory instead of breaking
   them.

 * `xsygst`: The reduction of a real symmetric-definite generalized eigenproblem
   to standard form can use an auxiliary buffer of size n^2 / 2 to avoid
   redundant computations.  It thereby performs about 30% less FLOPs than
   LAPACK.

FORTRAN symbol names
--------------------
ReLAPACK not only uses FORTRAN routines internally (small modifications of
original LAPACK routines to enable recursion) but is also commonly linked to
BLAS and LAPACK with standard FORTRAN interfaces.  Since FORTRAN compilers
commonly append an underscore to their symbol names, ReLAPACK has configuration
switches in `config.h` to adjust the library's symbol names.