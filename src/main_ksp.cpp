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

    char                config[PETSC_MAX_PATH_LEN]; // config file name



    // initialize PETSc and MPI
    ierr = PetscInitialize(&argc, &argv, nullptr, nullptr); CHKERRQ(ierr);


    // allow PETSc to read run-time options from a file
    ierr = PetscOptionsGetString(nullptr, nullptr, "-config",
            config, PETSC_MAX_PATH_LEN, nullptr); CHKERRQ(ierr);
    ierr = PetscOptionsInsertFile(PETSC_COMM_WORLD,
            nullptr, config, PETSC_FALSE); CHKERRQ(ierr);


    // create DMDA object
    ierr = DMDACreate3d(PETSC_COMM_WORLD, 
            DM_BOUNDARY_GHOSTED, DM_BOUNDARY_GHOSTED, DM_BOUNDARY_GHOSTED,
            DMDA_STENCIL_STAR, 
            Nx, Ny, Nz,
            PETSC_DECIDE, PETSC_DECIDE, PETSC_DECIDE,
            1, 1, nullptr, nullptr, nullptr, &da); CHKERRQ(ierr);

    // force to use AIJ format
    ierr = DMSetMatType(da, MATAIJ); CHKERRQ(ierr);

    // get partitioning info
    ierr = DMDAGetLocalInfo(da, &info); CHKERRQ(ierr);


    // create vectors and matrix
    ierr = DMCreateGlobalVector(da, &lhs); CHKERRQ(ierr);
    ierr = DMCreateGlobalVector(da, &rhs); CHKERRQ(ierr);
    ierr = DMCreateGlobalVector(da, &exact); CHKERRQ(ierr);
    ierr = DMCreateMatrix(da, &A); CHKERRQ(ierr);


    // setup the system: RHS, matrix A, and exact solution
    ierr = generateRHS(da, rhs); CHKERRQ(ierr);
    ierr = generateExt(da, exact); CHKERRQ(ierr);
    ierr = generateA(da, A); CHKERRQ(ierr);

    // handle the issue of all-Neumann BC matrix
    ierr = setRefPoint(A, rhs, exact); CHKERRQ(ierr);


    // create a solver
    ierr = KSPCreate(PETSC_COMM_WORLD, &ksp); CHKERRQ(ierr);
    ierr = KSPSetOperators(ksp, A, A); CHKERRQ(ierr);
    ierr = KSPSetType(ksp, KSPCG); CHKERRQ(ierr);
    ierr = KSPSetReusePreconditioner(ksp, PETSC_TRUE); CHKERRQ(ierr);
    ierr = KSPSetFromOptions(ksp); CHKERRQ(ierr);


    // solve
    ierr = VecSet(lhs, 0.0); CHKERRQ(ierr);
    ierr = KSPSolve(ksp, rhs, lhs); CHKERRQ(ierr);

    // check if the solve converged
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
            "L2 norm of final residual: %f\n" "Maximum norm of error: %f\n",
            info.mx, info.my, info.mz, Niters, res, Linf); CHKERRQ(ierr);


    // destroy PETSc objects
    ierr = KSPDestroy(&ksp); CHKERRQ(ierr);
    ierr = DMDestroy(&da); CHKERRQ(ierr);
    ierr = MatDestroy(&A); CHKERRQ(ierr);
    ierr = VecDestroy(&lhs); CHKERRQ(ierr);
    ierr = VecDestroy(&rhs); CHKERRQ(ierr);
    ierr = VecDestroy(&exact); CHKERRQ(ierr);


    // finalize PETSc
    ierr = PetscFinalize(); CHKERRQ(ierr);

    return 0;
}
