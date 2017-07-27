#! /bin/sh
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
    printf "ERROR: This script is for Titan@ORNL!! Exit now.\n"
    exit 1
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

if [[ "${CURRENT_PGI}" = "pgi/17.5.0"* ]];
then
    printf "Current PGI version is ${CURRENT_PGI}. No need to switch.\n"
else
    printf "Current PGI version is ${CURRENT_PGI}. Switching to pgi/17.5.0 ... "
    module switch ${CURRENT_PGI} pgi/17.5.0
    printf "done.\n"
fi

# ==============
# Check GCC
# ==============

CURRENT_GCC=`module list -t 2>&1 | grep "^gcc\/"`

if [[ "${CURRENT_GCC}" = "gcc/6.3.0"* ]];
then
    printf "Current GCC version is ${CURRENT_PGI}. No need to switch.\n"
elif [[ "${CURRENT_GCC}" = "" ]];
then
    printf "No GCC found. Loading gcc/6.3.0 ... "
    module load gcc/6.3.0
    printf "done.\n"
else
    printf "Current GCC version is ${CURRENT_GCC}. Switching to gcc/6.3.0 ... "
    module switch ${CURRENT_GCC} gcc/6.3.0
    printf "done.\n"
fi

printf "Regenerating .mypgcpprc in ${HOME} ... "
$PGI_PATH/linux86-64/default/bin/makelocalrc $PGI_PATH/linux86-64/default/bin \
    -gcc /opt/gcc/6.3.0/bin/gcc \
    -gpp /opt/gcc/6.3.0/bin/g++ \
    -g77 /opt/gcc/6.3.0/bin/gfortran \
    -x -o > ${HOME}/.mypgcpprc 2>/dev/null
printf "done.\n"

# ==============
# Reload Score-P
# ==============

printf "Reloading Score-P ... "
module unload scorep
SCOREP_STATUS=`module load scorep 2>&1 | sed "s/Loading\ Score-P\ for\ pgi\/.*/SUCCESS/g"`
if [[ ${SCOREP_STATUS} = "SUCCESS" ]];
then
    module load scorep 2>/dev/null
    printf "done.\n"
else
    printf "failed.\n"
    printf "Can not load Score-P. "
    printf "Maybe this shell script is outdated or something wrong on Titan. "
    printf "The error message is:\n"
    module load scorep
fi
