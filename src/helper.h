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
