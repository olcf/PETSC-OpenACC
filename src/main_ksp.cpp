/**
 * \file main.cpp
 * \brief An example and benchmark of AmgX and PETSc with Poisson system.
 *
 * The Poisson equation we solve here is
 *      \nabla^2 u(x, y) = -8\pi^2 \cos{2\pi x} \cos{2\pi y}
 * for 2D. And
 *      \nabla^2 u(x, y, z) = -12\pi^2 \cos{2\pi x} \cos{2\pi y} \cos{2\pi z}
 * for 3D.
 *
 * The exact solutions are
 *      u(x, y) = \cos{2\pi x} \cos{2\pi y}
 * for 2D. And
 *      u(x, y, z) = \cos{2\pi x} \cos{2\pi y} \cos{2\pi z}
 * for 3D.
 *
 * \author Pi-Yueh Chuang (pychuang@gwu.edu)
 * \date 2017-06-26
 */


// PETSc
# include <petsctime.h>
# include <petscsys.h>
# include <petscmat.h>
# include <petscvec.h>
# include <petscksp.h>

// headers
# include "helper.h"

// constants
# define Nx -100
# define Ny -100
# define Nz -100

int main(int argc, char **argv)
{
    PetscErrorCode      ierr;       // error codes returned by PETSc routines

    DM                  da;         // DM object

    DMDALocalInfo       info;       // partitioning info

    Vec                 lhs,        // left hand side
                        rhs,        // right hand side
                        exact;      // exact solution

    Mat                 A;          // coefficient matrix

    KSP                 ksp;        // PETSc KSP solver instance

    KSPConvergedReason  reason;     // KSP convergence/divergence reason

    PetscInt            Niters;     // iterations used to converge

    PetscReal           res,        // final residual
                        Linf;       // maximum norm

    PetscLogDouble      start,      // time at the begining
                        initSys,    // time after init the sys
                        initSolver, // time after init the solver
                        solve;      // time after solve

    char                config[PETSC_MAX_PATH_LEN]; // config file name



    // initialize MPI and PETSc
    ierr = MPI_Init(&argc, &argv); CHKERRQ(ierr);
    ierr = PetscInitialize(&argc, &argv, nullptr, nullptr); CHKERRQ(ierr);

    // allow PETSc to read run-time options from a file
    ierr = PetscOptionsGetString(nullptr, nullptr, "-config",
            config, PETSC_MAX_PATH_LEN, nullptr); CHKERRQ(ierr);
    ierr = PetscOptionsInsertFile(PETSC_COMM_WORLD,
            nullptr, config, PETSC_FALSE); CHKERRQ(ierr);

    // get time
    ierr = PetscTime(&start); CHKERRQ(ierr);

    // prepare the linear system
    ierr = createSystem(Nx, Ny, Nz, da, A, lhs, rhs, exact); CHKERRQ(ierr);

    // get system info
    ierr = DMDAGetLocalInfo(da, &info); CHKERRQ(ierr);

    // get time
    ierr = PetscTime(&initSys); CHKERRQ(ierr);

    // create a solver
    ierr = KSPCreate(PETSC_COMM_WORLD, &ksp); CHKERRQ(ierr);
    ierr = KSPSetOperators(ksp, A, A); CHKERRQ(ierr);
    ierr = KSPSetType(ksp, KSPCG); CHKERRQ(ierr);
    ierr = KSPSetReusePreconditioner(ksp, PETSC_TRUE); CHKERRQ(ierr);
    ierr = KSPSetFromOptions(ksp); CHKERRQ(ierr);
    ierr = KSPSetUp(ksp); CHKERRQ(ierr);

    // get time
    ierr = PetscTime(&initSolver); CHKERRQ(ierr);

    // solve the system
    ierr = KSPSolve(ksp, rhs, lhs); CHKERRQ(ierr);

    // get time
    ierr = PetscTime(&solve); CHKERRQ(ierr);

    // check if the solver converged
    ierr = KSPGetConvergedReason(ksp, &reason); CHKERRQ(ierr);
    if (reason < 0) SETERRQ1(PETSC_COMM_WORLD,
            PETSC_ERR_CONV_FAILED, "Diverger reason: %d\n", reason);

    // get the number of iterations
    ierr = KSPGetIterationNumber(ksp, &Niters); CHKERRQ(ierr);

    // get the L2 norm of final residual
    ierr = KSPGetResidualNorm(ksp, &res);

    // calculate error norm (maximum norm)
    ierr = VecAXPY(lhs, -1.0, exact); CHKERRQ(ierr);
    ierr = VecNorm(lhs, NORM_INFINITY, &Linf); CHKERRQ(ierr);

    // print result
    ierr = PetscPrintf(PETSC_COMM_WORLD,
            "[Nx, Ny, Nz]: [%d, %d, %d]\n" "Number of iterations: %d\n"
            "L2 norm of final residual: %f\n" "Maximum norm of error: %f\n"
            "Time [init, create solver, solve]: [%f, %f, %f]\n",
            info.mx, info.my, info.mz, Niters, res, Linf,
            initSys-start, initSolver-initSys, solve-initSolver); CHKERRQ(ierr);

    // destroy KSP solver
    ierr = KSPDestroy(&ksp); CHKERRQ(ierr);

    // destroy the linear system
    ierr = destroySystem(da, A, lhs, rhs, exact); CHKERRQ(ierr);

    // finalize PETSc and MPI
    ierr = PetscFinalize(); CHKERRQ(ierr);
    ierr = MPI_Finalize(); CHKERRQ(ierr);

    return 0;
}
