#! /bin/sh
#
# petsc.sh
# Copyright (C) 2017 Pi-Yueh Chuang <pychuang@gwu.edu>
#
# Distributed under terms of the MIT license.
#


# path to the directory containing this script. In case users launch this script
# at other location, # SCRIPT_DIR can be used as a reference point to the whole
# project directory.
SCRIPT_DIR=$(dirname $(readlink -f ${0}))
WORKING_DIR=${SCRIPT_DIR}/../


# ==============
# Download
# ==============

cd ${WORKING_DIR}

if [[ -e petsc-lite-3.7.6.tar.gz ]];
then
    CORRECT=`echo "f2310cc0663848cbdcdf2ddf8ac48246a43d336b *petsc-lite-3.7.6.tar.gz" | sha1sum -c -`
    if [[ ${CORRECT} = *"OK" ]];
    then
        printf "petsc-lite-3.7.6.tar.gz already exists. Skip downloading.\n"
    else
        printf "sha1sum doesn't match. exit now\n"
        exit 1
    fi
else
    printf "Downloading PETSc 3.7.6 ... "
    wget --quiet \
        http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-3.7.6.tar.gz
    printf "done.\n"
fi


# ==============
# Extract
# ==============

printf "Extracting PETSc 3.7.6 ... "
tar -xzf petsc-lite-3.7.6.tar.gz
printf "done.\n"


# ==============
# Patch
# ==============

printf "Patching petsc-3.7.6/src/mat/impls/aij/seq/aij.c ... "
patch -i patches/seq_aij.patch petsc-3.7.6/src/mat/impls/aij/seq/aij.c
printf "done.\n"

printf "Patching petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py ... "
patch -i patches/f2cblaslapack.patch petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py
printf "done.\n"


# ==============
# Build PETSc
# ==============

cd ${WORKING_DIR}/petsc-3.7.6

source ${SCRIPT_DIR}/petsc_configure_release.sh

make PETSC_DIR=/ccs/home/pychuang/Codes/ORNL-OpenACC/petsc-3.7.6 \
    PETSC_ARCH=RELEASE-TITAN all


# ==============
# Build PETSc with Score-P
# ==============

cd ${WORKING_DIR}/petsc-3.7.6

source ${SCRIPT_DIR}/petsc_configure_scorep.sh

cd SCOREP_TITAN/externalpackages/f2cblaslapack-3.4.2.q1

make -f ./tmpmakefile cleanblaslapack cleanlib
make -f ./tmpmakefile -j16 single double
cp libf2cblas.a libf2clapack.a ../../lib
cd ../../../

make PETSC_DIR=/ccs/home/pychuang/Codes/ORNL-OpenACC/petsc-3.7.6 \
    PETSC_ARCH=SCOREP-TITAN all


# ==============
# End
# ==============
cd ${WORKING_DIR}
