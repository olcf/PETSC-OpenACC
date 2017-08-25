# use `source`. Do not use a new shell.

sed -i "/include\ \${PETSC_DIR}\/conf\/base/d" makefile || return

printf "Making release build (see f2cblaslapack-release.log for progress) ... "
make \
    COPTFLAGS="-w -tp=bulldozer-64 -O3 -fast -Mnodwarf" \
    single double -j \
    > ${WORKING_DIR}/f2cblaslapack-release.log 2>&1 || return
printf "done.\n"
