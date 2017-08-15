#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=2:00:00
#PBS -l nodes=1
#PBS -l gres=atlas1%atlas2
#PBS -m e
#PBS -M chuangp@ornl.gov

# check if variable PROJFOLDER is set and if ${MEMBERWORK}/${PROJFOLDER} is valid
if [[ ! -d ${MEMBERWORK}/${PROJFOLDER:?PROJFOLDER should be set first} ]];
then
    printf "${MEMBEROWRK}/${PROJFOLDER} is not usable!\n"
    printf "Please check both MEMBERWORK and PROJFOLDER are set correctly!\n"
    exit
fi

# source environment variables
source ${PBS_O_WORKDIR}/scripts/set_up_environment.sh

# the name to this run case
RUN=`basename "${PBS_JOBNAME}" ".pbs"`

# the path to the base of this run
RUN_BASE=${PBS_O_WORKDIR}/runs

# the path to the directory where we put results of this run
RUN_PATH=${RUN_BASE}/${RUN}

# the path to the log file
LOG=${RUN_PATH}/${RUN}-${EXEC}-${PBS_JOBID}-`date +%Y%m%d-%X`.log

# create the RUN_PATH if it does not exist
if [ ! -d ${RUN_PATH} ]; then mkdir ${RUN_PATH}; fi

# sync the run folder to ${MEMBERWORK}/${PROJFOLDER}
rsync -Pravq --delete ${RUN_PATH} ${MEMBERWORK}/${PROJFOLDER}

# change the current path to ${MEMBERWORK}/${PROJFOLDER}/${RUN}
cd ${MEMBERWORK}/${PROJFOLDER}/${RUN}

# sync necessary files here for running on computing nodes
rsync -Pravq ${RUN_BASE}/../bin ${MEMBERWORK}/${PROJFOLDER}
rsync -Pravq ${RUN_BASE}/../configs ${MEMBERWORK}/${PROJFOLDER}

# For Titan, this allows multiple MPI processes to launch tasks on a single GPU
export CRAY_CUDA_PROXY=1

# start runs
echo "Single Node Strong Scaling: ${EXEC}" > ${LOG}
echo "===================================================" >> ${LOG}

date >> ${LOG}
echo "" >> ${LOG}

for i in 16 8 4 2 1
do
    echo "${i} Cores" >> ${LOG}
    echo "--------" >> ${LOG}
    aprun -n ${i} ${MEMBERWORK}/${PROJFOLDER}/bin/${EXEC} \
        -da_grid_x 300 \
        -da_grid_y 300 \
        -da_grid_z 300 \
        -config $MEMBERWORK/${PROJFOLDER}/configs/PETSc_SolverOptions_GAMG.info >> ${LOG}
    echo "" >> ${LOG}
    echo "" >> ${LOG}
done

# sync the results in ${MEMBERWORK}/${PROJFOLDER}/${RUN} to ${RUN_PATH}
rsync -Pravq ${MEMBERWORK}/${PROJFOLDER}/${RUN} ${RUN_BASE}
