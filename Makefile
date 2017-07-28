#
# Makefile
# Pi-Yueh Chuang, 2017-07-06 12:39
#


# directories
SRCDIR = ./src
OBJDIR = ./obj
BINDIR = ./bin


# set flags
ifeq (titan, $(findstring titan, $(shell hostname)))
	# prerequired
	# pgi/17.3.0
	# gcc/5.3.0
	# scorep
	# cray-petsc
    override CXX := CC
    override SCOREPCXX := scorep-CC
    override CXXFLAGS := -mp -std=c++11 -craype-verbose
	override LDFLAGS := -mp -acc -ta=tesla:cc35,host,multicore -craype-verbose
else
    override GET_PETSC_VARS := \
	    cat ${PETSC_DIR}/${PETSC_ARCH}/lib/petsc/conf/variables \
	    ${PETSC_DIR}/${PETSC_ARCH}/lib/petsc/conf/petscvariables

    override PETSC_CXX_FLAGS := \
	    $(shell ${GET_PETSC_VARS} | grep "^CXX_FLAGS[[:space:]]*=" | \
	    sed -e "s/CXX_FLAGS[[:space:]]*=[[:space:]]*//") \
	    $(shell ${GET_PETSC_VARS} | grep "^MPI_INCLUDE[[:space:]]*=" | \
	    sed -e "s/MPI_INCLUDE[[:space:]]*=[[:space:]]*//") \
	    $(shell ${GET_PETSC_VARS} | grep "^PETSC_CC_INCLUDES[[:space:]]*=" | \
	    sed -e "s/PETSC_CC_INCLUDES[[:space:]]*=[[:space:]]*//")

    override PETSC_LINK_FLAGS := \
	    $(shell ${GET_PETSC_VARS} | grep "^MPI_LIB[[:space:]]*=" | \
	    sed -e "s/MPI_LIB[[:space:]]*=[[:space:]]*//") \
	    $(shell ${GET_PETSC_VARS} | grep "^CC_LINKER_SLFLAG[[:space:]]*=" | \
	    sed -e "s/CC_LINKER_SLFLAG[[:space:]]*=[[:space:]]*//")$(shell ${GET_PETSC_VARS} | grep "^PETSC_LIB_DIR[[:space:]]*=" | \
	    sed -e "s/PETSC_LIB_DIR[[:space:]]*=[[:space:]]*//") \
	    $(shell ${GET_PETSC_VARS} | grep "^PETSC_WITH_EXTERNAL_LIB[[:space:]]*=" | \
	    sed -e "s/PETSC_WITH_EXTERNAL_LIB[[:space:]]*=[[:space:]]*//")

    CXX := $(shell ${GET_PETSC_VARS} | \
	    grep "^CXX[[:space:]]*=" | sed -e "s/CXX[[:space:]]*=[[:space:]]*//")

    SCOREPCXX := scorep-mpicxx

    override CXXFLAGS := -std=c++11 ${PETSC_CXX_FLAGS} ${CXXFLAGS}
    override LDFLAGS := ${LDFLAGS} -acc -ta=tesla:cc35,host,multicore ${PETSC_LINK_FLAGS}
endif


# Score-P flags
SCOREP_FLAGS = "--static --compiler --preprocess --memory --mpp=mpi --openacc --cuda" 


# phony targets
.PHONY: all \
	build-petsc \
	clean-build clean-petsc clean-all check-dir \
	petsc-ksp petsc-ksp-scorep \
	run-petsc-ksp-single-node-scaling \
	run-petsc-ksp-multiple-node-scaling \
	run-petsc-ksp-single-node-profiling \
	run-petsc-ksp-multiple-node-profiling

# target all
all: petsc-ksp petsc-ksp-scorep

# build PETSc library
build-petsc:
	sh -l scripts/petsc.sh

# makeing an executable binary petsc-ksp
petsc-ksp: check-dir ${BINDIR}/petsc-ksp

# makeing an executable binary petsc-ksp-scorep
petsc-ksp-scorep: check-dir ${BINDIR}/petsc-ksp-scorep

# makeing an executable binary petsc-ksp-scorep
petsc-ksp-pgprof: check-dir ${BINDIR}/petsc-ksp-pgprof

# run a strong scaling test on a single node
run-petsc-ksp-single-node-scaling:
	qsub runs/petsc-ksp-single-node-scaling.pbs

# run a strong scaling test on multiple nodes
run-petsc-ksp-multiple-node-scaling:
	qsub runs/petsc-ksp-multiple-node-scaling.pbs

# run a profiling with Score-P on a single node
run-petsc-ksp-single-node-scorep:
	qsub runs/petsc-ksp-single-node-scorep.pbs

# run a profiling with Score-P on multiple nodes
run-petsc-ksp-multiple-node-scorep:
	qsub runs/petsc-ksp-multiple-node-scorep.pbs

# run a profiling with PGprof on a single node
run-petsc-ksp-single-node-pgprof:
	qsub runs/petsc-ksp-single-node-pgprof.pbs

# run a profiling with PGprof on multiple nodes
run-petsc-ksp-multiple-node-pgprof:
	qsub runs/petsc-ksp-multiple-node-pgprof.pbs

# real target that creates petsc-ksp
${BINDIR}/petsc-ksp: ${OBJDIR}/helper.o ${OBJDIR}/main_ksp.o
	${CXX} -o $@ $^ ${LDFLAGS}

# real target that creates petsc-ksp-scorep
${BINDIR}/petsc-ksp-scorep: ${OBJDIR}/helper.scorep.o ${OBJDIR}/main_ksp.scorep.o
	SCOREP_WRAPPER_INSTRUMENTER_FLAGS=${SCOREP_FLAGS} \
		${SCOREPCXX} -o $@ $^ ${LDFLAGS}

# real target that creates petsc-ksp-pgprof
${BINDIR}/petsc-ksp-pgprof: ${OBJDIR}/helper.pgprof.o ${OBJDIR}/main_ksp.pgprof.o
	${CXX} -o $@ $^ ${LDFLAGS} -Minfo=accel -Mprof=ccff

# underlying target compiling C++ code
${OBJDIR}/%.o: ${SRCDIR}/%.cpp
	${CXX} -c -o $@ $< ${CXXFLAGS}

# underlying rule compiling C++ code with Score-P
${OBJDIR}/%.scorep.o: ${SRCDIR}/%.cpp
	SCOREP_WRAPPER_INSTRUMENTER_FLAGS=${SCOREP_FLAGS} \
		${SCOREPCXX} -c -o $@ $< ${CXXFLAGS}

# underlying rule compiling C++ code with PGprof profiling
${OBJDIR}/%.pgprof.o: ${SRCDIR}/%.cpp
	${CXX} -c -o $@ $< ${CXXFLAGS} -Minfo=ccff -Mprof=ccff

# check and create necessary directories
check-dir:
	@if [ ! -d ${OBJDIR} ]; then mkdir ${OBJDIR}; fi
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
