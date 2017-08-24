#!/bin/bash

./configure                                             \
    \
    --PETSC_ARCH=SCOREP-TITAN                           \
    --with-precision=double                             \
    --with-clanguage=C                                  \
    --with-shared-libraries=0                           \
    --with-debugger=pgdbg                               \
    --with-errorchecking=0                              \
    \
    --with-cc="cc"                                      \
    --with-clib-autodetect=0                            \
    --CFLAGS="-w -Minstrument"                          \
    --COPTFLAGS="-tp=bulldozer-64 -O3 -fast -Mnodwarf"  \
    \
    --with-cxx="CC"                                     \
    --with-cxxlib-autodetect=0                          \
    --CXXFLAGS="-w --gnu -Minstrument"                  \
    --CXXOPTFLAGS="-tp=bulldozer-64 -O3 -fast -Mnodwarf" \
    \
    --with-fc=0                                         \
    --with-fortran-datatypes=0                          \
    --with-fortran-interfaces=0                         \
    --with-fortranlib-autodetect=0                      \
    \
    --with-ar=ar                                        \
    --with-shared-ld=ar                                 \
    --with-ranlib=ranlib                                \
    \
    --with-gnu-compilers=0                              \
    --with-vendor-compilers="pgi"                       \
    --with-debugging=0                                  \
    --with-gcov=0                                       \
    --with-dependencies=0                               \
    --with-log=0                                        \
    \
    --known-has-attribute-aligned=1                     \
    --known-mpi-int64_t=0                               \
    --known-bits-per-byte=8                             \
    --known-sdot-returns-double=0                       \
    --known-snrm2-returns-double=0                      \
    --known-level1-dcache-assoc=4                       \
    --known-level1-dcache-linesize=64                   \
    --known-level1-dcache-size=16384                    \
    --known-memcmp-ok=1                                 \
    --known-mpi-c-double-complex=1                      \
    --known-mpi-long-double=0                           \
    --known-mpi-shared-libraries=0                      \
    --known-sizeof-MPI_Comm=4                           \
    --known-sizeof-MPI_Fint=4                           \
    --known-sizeof-char=1                               \
    --known-sizeof-double=8                             \
    --known-sizeof-float=4                              \
    --known-sizeof-int=4                                \
    --known-sizeof-long-long=8                          \
    --known-sizeof-long=8                               \
    --known-sizeof-short=2                              \
    --known-sizeof-size_t=8                             \
    --known-sizeof-void-p=8                             \
    --with-batch=1                                      \
    --with-scalar-type=real                             \
    --with-etags=0                                      \
    --with-x=0                                          \
    --with-ssl=0                                        \
    \
    --with-blas-lapack-dir=../f2cblaslapack-scorep
