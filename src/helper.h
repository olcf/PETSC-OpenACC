/**
 * \file helper.cpp
 * \brief prototypes of helper functions.
 * \author Pi-Yueh Chuang (pychuang@gwu.edu)
 * \date 2017-06-26
 */


# pragma once

// PETSc
# include <petscsys.h>
# include <petscdmda.h>
# include <petscvec.h>
# include <petscmat.h>


/**
 * \brief create the whole linear system A * lhs = rhs for the Poisson problem.
 *
 * \param Nx [in] the number of cells in x direction.
 * \param Ny [in] the number of cells in y direction.
 * \param Nz [in] the number of cells in z direction.
 * \param da [out] DMDA object.
 * \param A [out] coefficient matrix.
 * \param lhs [out] left-hand-side vector.
 * \param rhs [out] right-hand-side vector.
 * \param exact [out] exact solution vector.
 *
 * \return PetscErrorCode.
 */
PetscErrorCode createSystem(
        const PetscInt &Nx, const PetscInt &Ny, const PetscInt &Nz,
        DM &da, Mat &A, Vec &lhs, Vec &rhs, Vec &exact);


/**
 * \brief destroy the underlying data and unlink pointer of the linear system.
 *
 * \param da [in, out] DMDA object.
 * \param A [in, out] coefficient matrix.
 * \param lhs [in, out] left-hand-side vector.
 * \param rhs [in, out] right-hand-side vector.
 * \param exact [in, out] exact solution vector.
 *
 * \return PetscErrorCode.
 */
PetscErrorCode destroySystem(DM &da, Mat &A, Vec &lhs, Vec &rhs, Vec &exact);


/**
 * \brief assign values to right-hand-side Vec.
 *
 * \param grid [in] a DMDA object representing the grid.
 * \param rhs [out] the right-hand-side Vec object (must be created in advance).
 *
 * \return PetscErrorCode.
 */
PetscErrorCode generateRHS(const DM &grid, Vec &rhs);


/**
 * \brief assign values to exact solution Vec.
 *
 * \param grid [in] a DMDA object representing the grid.
 * \param exact [out] the exact solution Vec object (must be created in advance).
 *
 * \return PetscErrorCode.
 */
PetscErrorCode generateExt(const DM &grid, Vec &exact);


/**
 * \brief assign values to Laplacian operator (coefficient matrix) A.
 *
 * \param grid [in] a DMDA object representing the grid.
 * \param A [out] the Mat object (must be created in advance).
 *
 * \return PetscErrorCode.
 */
PetscErrorCode generateA(const DM &grid, Mat &A);


/**
 * \brief adjust the Laplacian matrix A with a reference point.
 *
 * This Poisson problem is an all-Neumann-BC problem. So we need to specify a
 * reference point.
 *
 * \param A [in, out] the Mat object.
 * \param rhs [in, out] the right-hand-side Vec object.
 * \param exact [in] the exact solution Vec object.
 *
 * \return PetscErrorCode.
 */
PetscErrorCode setRefPoint(Mat &A, Vec &rhs, const Vec &exact);
