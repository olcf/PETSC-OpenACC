/**
 * \file helper.cpp
 * \brief implementations of helper functions.
 * \author Pi-Yueh Chuang (pychuang@gwu.edu)
 * \date 2017-06-26
 */


// header
# include "helper.h"


// macro
# define Lx 1.0
# define Ly 1.0
# define Lz 1.0
# define c1 2.0*1.0*M_PI
# define c2 -3.0*c1*c1


// wrapper for creating the whole linear system
PetscErrorCode createSystem(
        const PetscInt &Nx, const PetscInt &Ny, const PetscInt &Nz,
        DM &da, Mat &A, Vec &lhs, Vec &rhs, Vec &exact)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    // create DMDA object
    ierr = DMDACreate3d(PETSC_COMM_WORLD, 
            DM_BOUNDARY_GHOSTED, DM_BOUNDARY_GHOSTED, DM_BOUNDARY_GHOSTED,
            DMDA_STENCIL_STAR, 
            Nx, Ny, Nz,
            PETSC_DECIDE, PETSC_DECIDE, PETSC_DECIDE,
            1, 1, nullptr, nullptr, nullptr, &da); CHKERRQ(ierr);

    // force to use AIJ format
    ierr = DMSetMatType(da, MATAIJ); CHKERRQ(ierr);

    // create vectors and matrix
    ierr = DMCreateGlobalVector(da, &lhs); CHKERRQ(ierr);
    ierr = DMCreateGlobalVector(da, &rhs); CHKERRQ(ierr);
    ierr = DMCreateGlobalVector(da, &exact); CHKERRQ(ierr);
    ierr = DMCreateMatrix(da, &A); CHKERRQ(ierr);

    // setup the system: RHS, matrix A, and exact solution; also initialize LHS with zeros
    ierr = VecSet(lhs, 0.0); CHKERRQ(ierr);
    ierr = generateRHS(da, rhs); CHKERRQ(ierr);
    ierr = generateExt(da, exact); CHKERRQ(ierr);
    ierr = generateA(da, A); CHKERRQ(ierr);

    // handle the issue of all-Neumann BC matrix
    ierr = setRefPoint(A, rhs, exact); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}


// destroy the linear system
PetscErrorCode destroySystem(DM &da, Mat &A, Vec &lhs, Vec &rhs, Vec &exact)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    ierr = VecDestroy(&exact); CHKERRQ(ierr);
    ierr = VecDestroy(&rhs); CHKERRQ(ierr);
    ierr = VecDestroy(&lhs); CHKERRQ(ierr);
    ierr = MatDestroy(&A); CHKERRQ(ierr);
    ierr = DMDestroy(&da); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}


// definition of 3D-version generateRHS
PetscErrorCode generateRHS(const DM &grid, Vec &rhs)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    DMDALocalInfo       info;

    PetscScalar         dx,
                        dy,
                        dz;

    PetscScalar         ***rhs_arry;

    // get partitioning information of the grid
    ierr = DMDAGetLocalInfo(grid, &info); CHKERRQ(ierr);

    // calculate dx, dy, dz
    dx = Lx / info.mx;
    dy = Ly / info.my;
    dz = Lz / info.mz;

    // get local underlying array of RHS
    ierr = DMDAVecGetArray(grid, rhs, &rhs_arry); CHKERRQ(ierr);

    // asign values to local part
    for(int k=info.zs; k<info.zs+info.zm; ++k)
        for(int j=info.ys; j<info.ys+info.ym; ++j)
            for(int i=info.xs; i<info.xs+info.xm; ++i)
                rhs_arry[k][j][i] = c2 * 
                    std::cos(c1 * (i + 0.5) * dx) * 
                    std::cos(c1 * (j + 0.5) * dy) * 
                    std::cos(c1 * (k + 0.5) * dz); 

    // return the control back to RHS Vec
    ierr = DMDAVecRestoreArray(grid, rhs, &rhs_arry); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}


// definition of 3D-version generateExt
PetscErrorCode generateExt(const DM &grid, Vec &exact)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    DMDALocalInfo       info;

    PetscScalar         dx,
                        dy,
                        dz;

    PetscScalar         ***exact_arry;

    // get partitioning information of the grid
    ierr = DMDAGetLocalInfo(grid, &info); CHKERRQ(ierr);

    // calculate dx, dy, dz
    dx = Lx / info.mx;
    dy = Ly / info.my;
    dz = Lz / info.mz;

    // get local underlying array of exact solution Vec
    ierr = DMDAVecGetArray(grid, exact, &exact_arry); CHKERRQ(ierr);

    for(int k=info.zs; k<info.zs+info.zm; ++k)
        for(int j=info.ys; j<info.ys+info.ym; ++j)
            for(int i=info.xs; i<info.xs+info.xm; ++i)
                exact_arry[k][j][i] = 
                    std::cos(c1 * (i + 0.5) * dx) * 
                    std::cos(c1 * (j + 0.5) * dy) * 
                    std::cos(c1 * (k + 0.5) * dz); 

    // return the control back to the exact solution Vec
    ierr = DMDAVecRestoreArray(grid, exact, &exact_arry); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}


// definition of 3D-version generateA
PetscErrorCode generateA(const DM &grid, Mat &A)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    DMDALocalInfo       info;

    PetscScalar         dx,
                        dy,
                        dz;

    ISLocalToGlobalMapping  mapping;

    MatStencil          s[7];

    PetscInt            cols[7];

    PetscReal           values[7];

    // get partitioning information of the grid
    ierr = DMDAGetLocalInfo(grid, &info); CHKERRQ(ierr);

    // get mapping between local and global data
    ierr = DMGetLocalToGlobalMapping(grid, &mapping); CHKERRQ(ierr);

    // calculate dx, dy, dz
    dx = Lx / info.mx;
    dy = Ly / info.my;
    dz = Lz / info.mz;

    // calculate coefficients
    values[1] = values[2] = 1.0 / (dx * dx);
    values[3] = values[4] = 1.0 / (dy * dy);
    values[5] = values[6] = 1.0 / (dz * dz);

    // loop through all local rows
    for(int k=info.zs; k<info.zs+info.zm; ++k)
    {
        s[0].k = s[1].k = s[2].k = s[3].k = s[4].k = k;
        s[5].k = k - 1;
        s[6].k = k + 1;

        for(int j=info.ys; j<info.ys+info.ym; ++j)
        {
            s[0].j = s[1].j = s[2].j = s[5].j = s[6].j = j;
            s[3].j = j - 1;
            s[4].j = j + 1;

            for(int i=info.xs; i<info.xs+info.xm; ++i)
            {
                s[0].i = s[3].i = s[4].i = s[5].i = s[6].i = i;
                s[1].i = i - 1;
                s[2].i = i + 1;

                // loop through all columns of this row
                for(int idx=0; idx<7; ++idx)
                {
                    // get local column index
                    ierr = DMDAConvertToCell(grid, s[idx], &cols[idx]);
                    CHKERRQ(ierr);
                }

                // convert to global column index
                ierr = ISLocalToGlobalMappingApply(
                        mapping, 7, cols, cols); CHKERRQ(ierr);

                // initialize the diagonal value
                values[0] = 0.0;

                // calculate diagonal value with all-Neumann-BC
                for(int idx=1; idx<7; ++idx)
                    if (cols[idx] > -1) values[0] -= values[idx];

                // set the values of this row
                ierr = MatSetValues(A, 1, &cols[0], 7, cols, values,
                        INSERT_VALUES); CHKERRQ(ierr);
            }
        }
    }

    ierr = MatAssemblyBegin(A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}


// set a reference point for this all-Neumann-BC problem
PetscErrorCode setRefPoint(Mat &A, Vec &rhs, const Vec &exact)
{
    PetscFunctionBeginUser;

    PetscErrorCode      ierr;

    PetscInt            row[1] = {0};

    PetscInt            n;

    PetscReal           scale;

    Vec                 diag;

    ierr = MatCreateVecs(A, nullptr, &diag); CHKERRQ(ierr);

    ierr = MatGetDiagonal(A, diag); CHKERRQ(ierr);

    ierr = VecGetSize(diag, &n); CHKERRQ(ierr);

    ierr = VecSum(diag, &scale); CHKERRQ(ierr);

    scale /= double(n);

    ierr = MatZeroRowsColumns(A, 1, row, scale, exact, rhs); CHKERRQ(ierr);

    ierr = VecDestroy(&diag); CHKERRQ(ierr);

    PetscFunctionReturn(0);
}
