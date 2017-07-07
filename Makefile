#
# Makefile
# Pi-Yueh Chuang, 2017-07-06 12:39
#

SRCDIR = ./src
OBJDIR = ./obj
BINDIR = ./bin

CFLAGS = -mp -craype-verbose
CXXFLAGS = -mp -std=c++11 -craype-verbose
LDFLAGS = -mp -craype-verbose

SCOREP_WRAPPER_INSTRUMENTER_FLAGS = --static --thread=none --mpp=mpi \
									--mutex=none --compiler --nocuda \
									--noonline-access --nopomp --noopenmp \
									--preprocess --noopencl --noopenacc --memory

SCOREP_WRAPPER_COMPILER_FLAGS = -w


.PHONY: all clean check-dir petsc-ksp petsc-ksp-scorep run-petsc-ksp-single-node-scaling


all: petsc-ksp petsc-ksp-scorep
petsc-ksp: check-dir ${BINDIR}/petsc-ksp
petsc-ksp-scorep: check-dir ${BINDIR}/petsc-ksp-scorep

run-petsc-ksp-single-node-scaling:
	qsub runs/petsc-ksp-single-node-scaling.pbs


${BINDIR}/petsc-ksp: ${OBJDIR}/helper.o ${OBJDIR}/main_ksp.o
	CC ${LDFLAGS} -o $@ $^


${BINDIR}/petsc-ksp-scorep: ${OBJDIR}/helper.scorep.o ${OBJDIR}/main_ksp.scorep.o
	scorep-CC ${LDFLAGS} -o $@ $^


${OBJDIR}/%.o: ${SRCDIR}/%.cpp
	CC -c ${CXXFLAGS} -o $@ $<


${OBJDIR}/%.scorep.o: ${SRCDIR}/%.cpp
	scorep-CC -c ${CXXFLAGS} -o $@ $<


check-dir:
	@if [ ! -d ${OBJDIR} ]; then mkdir ${OBJDIR}; fi
	@if [ ! -d ${BINDIR} ]; then mkdir ${BINDIR}; fi


clean:
	@rm -rf ${OBJDIR} ${BINDIR}

# vim:ft=make
#
