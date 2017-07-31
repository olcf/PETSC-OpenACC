#! /bin/sh -l
#
# set_up_environment.sh
# Copyright (C) 2017 Pi-Yueh Chuang <pychuang@gwu.edu>
#
# Distributed under terms of the MIT license.
#

# this file should be sourced to affect current shell


# ==============
# Check Titan
# ==============
HOSTNAME=`hostname`
if [[ ${HOSTNAME} != "titan-"* ]];
then
    printf "============================================================\n"
    printf "IMPORTANT: This script is for Titan at ORNL!!\n"
    printf "You may need to modify this script for your current machine!\n"
    printf "============================================================\n"
    return 1
fi


# ==============
# Check PrgEnv
# ==============

CURRENT_ENV=`module list -t 2>&1 | grep "^PrgEnv"`

if [[ "${CURRENT_ENV}" = "PrgEnv-pgi/"* ]];
then
    printf "Current PrgEnv is ${CURRENT_ENV}. No need to switch.\n"
else
    printf "Current PrgEnv is ${CURRENT_ENV}. Switching to PrgEnv-pgi ... "
    module switch ${CURRENT_ENV} PrgEnv-pgi
    printf "done.\n"
fi

# ==============
# Check PGI
# ==============

CURRENT_PGI=`module list -t 2>&1 | grep "^pgi\/"`

if [[ "${CURRENT_PGI}" = "pgi/16.10.0"* ]];
then
    printf "Current PGI version is ${CURRENT_PGI}. No need to switch.\n"
else
    printf "Current PGI version is ${CURRENT_PGI}. Switching to pgi/16.10.0 ... "
    module switch ${CURRENT_PGI} pgi/16.10.0
    printf "done.\n"
fi

# ==============
# Check GCC
# ==============

CURRENT_GCC=`module list -t 2>&1 | grep "^gcc\/"`

if [[ "${CURRENT_GCC}" = "gcc/4.9.3"* ]];
then
    printf "Current GCC version is ${CURRENT_GCC}. No need to switch.\n"
elif [[ "${CURRENT_GCC}" = "" ]];
then
    printf "No GCC found. Loading gcc/4.9.3 ... "
    module load gcc/4.9.3
    printf "done.\n"
else
    printf "Current GCC version is ${CURRENT_GCC}. Switching to gcc/4.9.3 ... "
    module switch ${CURRENT_GCC} gcc/4.9.3
    printf "done.\n"
fi

printf "Regenerating .mypgcpprc in ${HOME} ... "
$PGI_PATH/linux86-64/default/bin/makelocalrc $PGI_PATH/linux86-64/default/bin \
    -gcc /opt/gcc/4.9.3/bin/gcc \
    -gpp /opt/gcc/4.9.3/bin/g++ \
    -g77 /opt/gcc/4.9.3/bin/gfortran \
    -x -o > ${HOME}/.mypgcpprc 2>/dev/null
printf "done.\n"

# ==============
# Reload Score-P
# ==============

printf "Reloading Score-P ... "
module unload scorep
module load scorep
printf "done.\n"

CURRENT_SCOREP=`module list -t 2>&1 | grep "^scorep\/"`

if [[ ! ${CURRENT_SCOREP} = "scorep/3.1" ]];
then
    printf "\n"
    printf "Warning: the version of default SCORE-P module is not 3.1 "
    printf "You may encounter problems. "
    printf "If that happens, manually load Score-P 3.1 module.\n"
fi

# ==============
# Load cudatoolkit
# ==============

printf "Loading CUDA ... "
module unload cudatoolkit
module load cudatoolkit
printf "done.\n"

CURRENT_CUDA=`module list -t 2>&1 | grep "^cudatoolkit\/"`

if [[ ! "${CURRENT_CUDA}" = "cudatoolkit/7.5."* ]];
then
    printf "\n"
    printf "Warning: the version of default CUDA module is not 7.5. "
    printf "You may encounter problems. "
    printf "If that happens, manually load CUDA 7.5 module.\n"
fi

