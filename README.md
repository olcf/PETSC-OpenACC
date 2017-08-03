# PETSc-OpenACC

This project demonstrates the feasibility of migrating legacy PETSc-based 
applications to modern supercomputers (which are often heterogeneous platforms)
with minor code modifications in PETSc's source code.


## Introduction
------------------------------

[PETSc](https://www.mcs.anl.gov/petsc/) (Portable, Extensible Toolkit for
Scientific Computation) is an MPI-based parallel linear algebra library. It has 
been used to build many scientific codes in HPC (high-performance computing) 
area for over two decades. While PETSc provides excellent performance on CPU 
machines, it still lacks satisfying GPU support. Nowadays, GPUs play an 
increasingly important role in modern supercomputers, and due to PETSc's lagging
GPU support, PETSc-based applications may need to find other ways to move 
forward in hybrid accelerated systems.

This project demonstrates that, instead of waiting for PETSc's GPU support, it
is possible for the developers of PETSc applications to enable GPU capability in
some degree by applying minor code modifications directly to PETSc's source
code. Directive-based programming models, such as OpenACC, are suitable for this
kind of minor coding works.

The speedup may not be appealing in this way because we avoid re-design
numerical methods and parallel algorithms and. The sequential kernels called by
each MPI process in PETSc are originally designed for a single CPU core. Thus,
naively inserting OpenACC directives into source code may not be able to hide
data transfer latency efficiently. And some kernels are difficult to be
parallelized without re-designing their algorithms. 

Nevertheless, small speedups can still be useful to codes running on some
supercomputers, such as Titan and Summit. These supercomputers only provide
hybrid nodes and charge the same no matter a code is utilizing GPUs or not.
Hence, for PETSc applications running on those supercomputers, minor code
modifications in an exchange with GPU capability and small speedup may be
preferable.


## Description
------------------------------

* Target problem: a 3D Poisson problem, which represents a bottleneck of many
  CFD (computational fluid dynamics) codes.
* The KSP linear solver will be CG (conjugate-gradient method) + GAMG (algebra
  multigrid preconditioner)
* Target platform [Titan](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/)

Codes In **src/original** directory are original PETSc's kernel functions. We 
extract them from PETSc source files for convenience. Accelerated kernels will
be in other child folders under **src**. Then it's easier to compare the 
difference between original kernels and modified kernels.

In folder `runs`, there are some PBS scripts for running some tests/benchmarks 
on Titan. Users can submit these PBS jobs through `make` or `qsub` directly. But
jobs must submit under the top-level directory of this repo, because there are
some relative paths used.


## Usage
------------------------------

At top-level directory:

* `source ./scripts/set_up_environment.sh`: setup the environment on Titan
* `make help`: see help
* `make list`: list all targets
* `make list-executables`: list all targets for building executables
* `make list-runs`: list all targets for submitting PBS jobs
* `make build-petsc`: build PETSc library
* `make all`: build all executables
* `make <executable>`: build an individual executable
* `make PROJ=<chargeable project> <PBS run>`: submit a run under **runs**
  directory using the allocation of *\<chargeable proj\>*; or you can use
  alternative command `qsub -v PROJ=<chargeable project> runs/<PBS job>.pbs`
* `make clean-build`: clean executables and object files
* `make clean-petsc`: clean build PETSc library
* `make clean-all`: clean everything

## Contact

Use GitHub issue or email: <pychuang@gwu.edu>
