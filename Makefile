#
# Makefile
# Pi-Yueh Chuang, 2017-07-06 12:39
#


# set up environment
CXX := CC
CXXFLAGS := -std=c++11 -craype-verbose -w \
	-acc -ta=host,tesla:cc35 -Minfo=accel \
	-I./extra/petsc-3.7.6/include -I./extra/petsc-3.7.6/RELEASE-TITAN/include
LDFLAGS := -craype-verbose -acc -ta=host,tesla:cc35 -Minfo=accel

# directories
SRCDIR = ./src
OBJDIR = ./obj
BINDIR = ./bin
LIBDIR = ./lib

# Score-P flags
SCOREP_FLAGS = --static --mpp=mpi --openacc --verbose

# source files
SRC = helper.cpp main_ksp.cpp
KERNEL = MatAssemblyEnd_SeqAIJ.c MatDestroy_SeqAIJ.c MatMult_SeqAIJ.c

# PETSc
PETSCLIB = extra/petsc-3.7.6/RELEASE-TITAN/lib/libpetsc.a

# phony targets
.PHONY: all \
	build-petsc \
	clean-build clean-petsc clean-all check-dir \
	petsc-ksp-original petsc-ksp-scorep-original petsc-ksp-pgprof-original \
	petsc-ksp-openacc petsc-ksp-scorep-openacc petsc-ksp-pgprof-openacc \
	run-petsc-ksp-single-node-scaling \
	run-petsc-ksp-multiple-node-scaling \
	run-petsc-ksp-single-node-profiling \
	run-petsc-ksp-multiple-node-profiling

# preserve object files
.PRECIOUS: ${OBJDIR}/%.o

# target all
all: petsc-ksp-original petsc-ksp-scorep-original petsc-ksp-pgprof-original \
	petsc-ksp-openacc petsc-ksp-scorep-openacc petsc-ksp-pgprof-openacc

# build PETSc library
build-petsc: ${PETSCLIB}

# makeing an executable binary petsc-ksp-original
petsc-ksp-original: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-original

# makeing an executable binary petsc-ksp-openacc
petsc-ksp-openacc: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-openacc

# makeing an executable binary petsc-ksp-scorep-origina;
petsc-ksp-scorep-original: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-scorep-original

# makeing an executable binary petsc-ksp-scorep-openacc
petsc-ksp-scorep-openacc: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-scorep-openacc

# makeing an executable binary petsc-ksp-pgprof-origina;
petsc-ksp-pgprof-original: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-pgprof-original

# makeing an executable binary petsc-ksp-pgprof-openacc
petsc-ksp-pgprof-openacc: ${PETSCLIB} check-dir ${BINDIR}/petsc-ksp-pgprof-openacc

# real target that creates petsc-ksp-scorep-*
${BINDIR}/petsc-ksp-scorep-%: \
	$(foreach i, $(SRC:.cpp=.scorep.o), ${OBJDIR}/${i})\
	$(foreach i, $(KERNEL:.c=.scorep.o), ${OBJDIR}/%/${i})

	scorep ${SCOREP_FLAGS} ${CXX} -o $@ $^ ${LDFLAGS} ${PETSCLIB}

# real target that creates petsc-ksp-pgprof-*
${BINDIR}/petsc-ksp-pgprof-%: \
	$(foreach i, $(SRC:.cpp=.pgprof.o), ${OBJDIR}/${i})\
	$(foreach i, $(KERNEL:.c=.pgprof.o), ${OBJDIR}/%/${i})

	${CXX} -Mprof=ccff -pg -Minstrument -o $@ $^ ${LDFLAGS} ${PETSCLIB}

# real target that creates petsc-ksp-*
${BINDIR}/petsc-ksp-%: \
	$(foreach i, $(SRC:.cpp=.o), ${OBJDIR}/${i})\
	$(foreach i, $(KERNEL:.c=.o), ${OBJDIR}/%/${i})

	${CXX} -o $@ $^ ${LDFLAGS} ${PETSCLIB}

# underlying target to build PETSc
${PETSCLIB}: \
	$(wildcard extra/petsc-3.7.6/src/**/*.c) \
	$(wildcard extra/petsc-3.7.6/src/**/*.h)
	sh -l scripts/petsc.sh

# underlying rule compiling C++ code with Score-P
${OBJDIR}/%.scorep.o: ${SRCDIR}/%.cpp
	scorep ${SCOREP_FLAGS} ${CXX} -c -o $@ $< ${CXXFLAGS}

# underlying rule compiling C code with Score-P
${OBJDIR}/%.scorep.o: ${SRCDIR}/%.c
	scorep ${SCOREP_FLAGS} ${CXX} -c -o $@ $< ${CXXFLAGS}

# underlying rule compiling C++ code with PGprof
${OBJDIR}/%.pgprof.o: ${SRCDIR}/%.cpp
	${CXX} -Mprof=ccff -pg -Minstrument -c -o $@ $< ${CXXFLAGS}

# underlying rule compiling C code with PGprof
${OBJDIR}/%.pgprof.o: ${SRCDIR}/%.c
	${CXX} -Mprof=ccff -c -o $@ $< ${CXXFLAGS}

# underlying target compiling C++ code
${OBJDIR}/%.o: ${SRCDIR}/%.cpp
	${CXX} -c -o $@ $< ${CXXFLAGS}

# underlying target compiling C code
${OBJDIR}/%.o: ${SRCDIR}/%.c
	${CXX} -c -o $@ $< ${CXXFLAGS}

# rule to run PBS script in directory "runs"
run-%: runs/%.pbs
	qsub $<

# check and create necessary directories
check-dir:
	@if [ ! -d ${OBJDIR} ]; then mkdir ${OBJDIR}; fi
	@if [ ! -d ${OBJDIR}/original ]; then mkdir ${OBJDIR}/original; fi
	@if [ ! -d ${OBJDIR}/openacc ]; then mkdir ${OBJDIR}/openacc; fi
	@if [ ! -d ${BINDIR} ]; then mkdir ${BINDIR}; fi

# clean executables and object files
clean-build:
	@rm -rf ${OBJDIR} ${BINDIR}

# clean everything from PETSc
clean-petsc:
	@rm -rf extra

# clean everything
clean-all: clean-build clean-petsc

# vim:ft=make
