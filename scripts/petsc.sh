#! /bin/sh -l
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

# set up environment, in case users didn't do that in advance
source ${SCRIPT_DIR}/set_up_environment.sh

# create a folder for PETSc files
if [[ ! -d extra ]];
then
    mkdir extra || return 1
fi


# ==============
# Download
# ==============

# go to the top level of this ORNL-OpenACC project
cd ${WORKING_DIR}/extra || return 1

# if tarbal already exists, don't download it
if [[ -e petsc-lite-3.7.6.tar.gz ]];
then
    printf "petsc-lite-3.7.6.tar.gz already exists. Skip downloading.\n"
else
    printf "Downloading PETSc 3.7.6 ... "
    wget --quiet \
        http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-3.7.6.tar.gz \
        || return
    printf "done.\n"
fi

# check if the downloaded tarbal is correct
SUCCESS=`echo "f2310cc0663848cbdcdf2ddf8ac48246a43d336b *petsc-lite-3.7.6.tar.gz" | sha1sum -c -`
if [[ ! ${SUCCESS} = *"OK" ]];
then
    printf "sha1sum doesn't match. exit now\n"
    return 1
fi


# ==============
# Extract
# ==============

printf "Extracting PETSc 3.7.6 ... "
tar -k -xzf petsc-lite-3.7.6.tar.gz || return
printf "done.\n"

PETSC_DIR=${WORKING_DIR}/extra/petsc-3.7.6


# ==============
# Patch
# ==============

# re-extract original aij.c, in case aij.c has already been patched
tar -xzf petsc-lite-3.7.6.tar.gz petsc-3.7.6/src/mat/impls/aij/seq/aij.c || return

# this patch remove our OpenACC target functions from aij.c
printf "Patching petsc-3.7.6/src/mat/impls/aij/seq/aij.c ... "
patch -s -i ${WORKING_DIR}/patches/seq_aij.patch \
    ${PETSC_DIR}/src/mat/impls/aij/seq/aij.c || return
printf "done.\n"

# re-extract original f2cblaslapack.py, in case it has already been patched
tar -xzf petsc-lite-3.7.6.tar.gz petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py || return

# this patch let make build f2cblaslapack package in parallel and turn off Score-P wrapper
printf "Patching petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py ... "
patch -s -i ${WORKING_DIR}/patches/f2cblaslapack.patch \
    ${PETSC_DIR}/config/BuildSystem/config/packages/f2cblaslapack.py || return
printf "done.\n"


# ==============
# Configure PETSc
# ==============

# go to PETSc source folder
cd ${PETSC_DIR} || return

# configure the release build
printf "Configuring release build (see release_config.log for progress) ... "
source ${SCRIPT_DIR}/petsc_configure_release.sh > release_config.log 2>&1

# check if the configuration for release build completed
SUCCESS=`tail release_config.log | grep -c "Configure\ stage\ complete\."`
if [[ ${SUCCESS} = "0" ]];
then
    printf "Release build failed!!\n"
    return 1
fi

printf "done.\n"


# ==============
# Build PETSc with Score-P
# ==============

# go back to PETSc top folder
cd ${PETSC_DIR} || return

# make the release build
printf "Making release build ... "
make \
    PETSC_DIR=${PETSC_DIR} \
    PETSC_ARCH=RELEASE-TITAN all > release_make.log 2>&1 || return
printf "done.\n"


# ==============
# End
# ==============
cd ${WORKING_DIR} || return
