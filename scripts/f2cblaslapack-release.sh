#! /bin/sh
#
# f2cblaslapack-release.sh
# Copyright (C) 2017 Pi-Yueh Chuang <pychuang@gwu.edu>
#
# Distributed under terms of the MIT license.
#


sed -i "/include\ \${PETSC_DIR}\/conf\/base/d" makefile || return

printf "Making release build (see f2cblaslapack-release.log for progress) ... "
make \
    COPTFLAGS="-w -tp=bulldozer-64 -O3 -fast -Mnodwarf" \
    single double -j \
    > ${WORKING_DIR}/f2cblaslapack-release.log 2>&1 || return
printf "done.\n"
