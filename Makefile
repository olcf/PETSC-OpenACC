#
# Makefile
# Pi-Yueh Chuang, 2017-07-06 12:39
#

SRCDIR = ./src
OBJDIR = ./obj
BINDIR = ./bin

CFLAGS = -craype-verbose
CXXFLAGS = -std=c++11 -craype-verbose
LDFLAGS = -mp -craype-verbose


.PHONY: clean check-dir


all:
	@echo "Makefile needs your attention"

petsc-ksp: check-dir ${OBJDIR}/helper.o ${OBJDIR}/main_ksp.o
	CC ${LDFLAGS} -o ${BINDIR}/$@ ${OBJDIR}/helper.o ${OBJDIR}/main_ksp.o


${OBJDIR}/%.o: ${SRCDIR}/%.c
	cc -c -mp ${CFLAGS} -o $@ $<


${OBJDIR}/%.o: ${SRCDIR}/%.cpp
	CC -c -std=c++11 -mp ${CXXFLAGS} -o $@ $<


check-dir:
	if [ ! -d ${OBJDIR} ]; then mkdir ${OBJDIR}; fi
	if [ ! -d ${BINDIR} ]; then mkdir ${BINDIR}; fi


clean:
	rm -rf ${OBJDIR} ${BINDIR}

# vim:ft=make
#
