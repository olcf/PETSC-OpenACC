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

# create src/original directory
printf "Creating src/original directory ... "
if [[ ! -d ${WORKING_DIR}/src/original ]];
then
    mkdir ${WORKING_DIR}/src/original
fi
printf "done.\n"

# extract kernel functions
printf "Extracing source code of kernel functions to src/original ... "
sed -n "8,11p;973,1032p" petsc-3.7.6/src/mat/impls/aij/seq/aij.c > \
    ${WORKING_DIR}/src/original/MatAssemblyEnd_SeqAIJ.c
sed -n "8,11p;1076,1121p" petsc-3.7.6/src/mat/impls/aij/seq/aij.c > \
    ${WORKING_DIR}/src/original/MatDestroy_SeqAIJ.c
sed -n "8,11p;1277,1335p" petsc-3.7.6/src/mat/impls/aij/seq/aij.c >  \
    ${WORKING_DIR}/src/original/MatMult_SeqAIJ.c

# remove kernels from original PETSc source code
sed -i "973,1032d;1076,1121d;1277,1335d" petsc-3.7.6/src/mat/impls/aij/seq/aij.c
printf "done.\n"

# re-extract original f2cblaslapack.py, in case it has already been patched
tar -xzf petsc-lite-3.7.6.tar.gz petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py || return

# let make use 16 cores for f2cblaslapack
printf "Let make use 16 cores for building f2cblaslapack ... "
sed -i "s/make\ -f\ tmpmakefile\ '+make_target/make\ -j16\ -f\ tmpmakefile\ '+make_target/g" \
    petsc-3.7.6/config/BuildSystem/config/packages/f2cblaslapack.py
printf "done.\n"

# create OpenACC version of kernels based on PETSc original kernel
printf "Creating OpenACC kernels based on original PETSc kernels ...\n\n"

rm -f ${WORKING_DIR}/src/openacc-step*/*.c

for i in {1..4};
do
    printf "\tPatching openacc-step${i} ...\n\n"

    for p in ${WORKING_DIR}/src/openacc-step${i}/*.patch;
    do
        name=$(basename ${p})

        patch -N \
            -i ${WORKING_DIR}/src/openacc-step${i}/${name} \
            -o ${WORKING_DIR}/src/openacc-step${i}/${name%.*}.c \
            ${WORKING_DIR}/src/original/${name%.*}.c
    done

    printf "\n"
done

cp ${WORKING_DIR}/src/original/MatAssemblyEnd_SeqAIJ.c ${WORKING_DIR}/src/openacc-step1
cp ${WORKING_DIR}/src/original/MatDestroy_SeqAIJ.c ${WORKING_DIR}/src/openacc-step1

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
