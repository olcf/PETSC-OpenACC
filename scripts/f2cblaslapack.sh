#! /bin/sh -l
#
# f2cblaslapack.sh
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
if [[ -e f2cblaslapack-3.4.2.q1.tar.gz ]];
then
    printf "f2cblaslapack-3.4.2.q1.tar.gz already exists. Skip downloading.\n"
else
    printf "Downloading f2cblaslapack 3.4.2.q1 ... "
    wget --quiet \
        http://ftp.mcs.anl.gov/pub/petsc/externalpackages/f2cblaslapack-3.4.2.q1.tar.gz \
        || return
    printf "done.\n"
fi

# check if the downloaded tarbal is correct
SUCCESS=`echo "34571c3e2680ffc41aeeac452fecd369f2ee6975 *f2cblaslapack-3.4.2.q1.tar.gz" | sha1sum -c -`
if [[ ! ${SUCCESS} = *"OK" ]];
then
    printf "sha1sum doesn't match. exit now\n"
    return 1
fi


# ==============
# Extract
# ==============

# create a folder for f2cblaslapack-${1}
if [[ ! -d f2cblaslapack-${1} ]];
then
    mkdir f2cblaslapack-${1} || return 1
fi

printf "Extracting f2cblaslapack to f2cblaslapack-${1} ... "
tar -xzf f2cblaslapack-3.4.2.q1.tar.gz \
    -C f2cblaslapack-${1} --strip-components=1 || return
printf "done.\n"

F2CBLASLAPACK_DIR=${WORKING_DIR}/extra/f2cblaslapack-${1}


# ==============
# Build Release
# ==============

cd ${F2CBLASLAPACK_DIR} || return

source ${SCRIPT_DIR}/f2cblaslapack-${1}.sh


# ==============
# End
# ==============
cd ${WORKING_DIR} || return
