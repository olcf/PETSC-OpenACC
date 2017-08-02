#include <../src/mat/impls/aij/seq/aij.h>          /*I "petscmat.h" I*/
#include <petscblaslapack.h>
#include <petscbt.h>
#include <petsc/private/kernels/blocktranspose.h>

// OpenACC header
# include <openacc.h>

PetscScalar single_row_mult(const PetscInt n, const PetscInt *cols, 
        const MatScalar *data, const PetscScalar *x);

#undef __FUNCT__
#define __FUNCT__ "MatMult_SeqAIJ"
PetscErrorCode MatMult_SeqAIJ(Mat A,Vec xx,Vec yy)
{
  Mat_SeqAIJ        *a = (Mat_SeqAIJ*)A->data;
  PetscScalar       *y;
  const PetscScalar *x;
  const MatScalar   *aa;
  PetscErrorCode    ierr;
  PetscInt          m=A->rmap->n;
  const PetscInt    *aj,*ii,*ridx=NULL;
  PetscInt          n,i;
  PetscScalar       sum;
  PetscBool         usecprow=a->compressedrow.use;

#if defined(PETSC_HAVE_PRAGMA_DISJOINT)
#pragma disjoint(*x,*y,*aa)
#endif

  PetscFunctionBegin;
  ierr = VecGetArrayRead(xx,&x);CHKERRQ(ierr);
  ierr = VecGetArray(yy,&y);CHKERRQ(ierr);
  ii   = a->i;
  if (usecprow) { /* use compressed row format */
    ierr = PetscMemzero(y,m*sizeof(PetscScalar));CHKERRQ(ierr);
    m    = a->compressedrow.nrows;
    ii   = a->compressedrow.i;
    ridx = a->compressedrow.rindex;
    for (i=0; i<m; i++) {
      n           = ii[i+1] - ii[i];
      aj          = a->j + ii[i];
      aa          = a->a + ii[i];
      sum         = 0.0;
      PetscSparseDensePlusDot(sum,x,aa,aj,n);
      /* for (j=0; j<n; j++) sum += (*aa++)*x[*aj++]; */
      y[*ridx++] = sum;
    }
  } else { /* do not use compressed row format */
#if defined(PETSC_USE_FORTRAN_KERNEL_MULTAIJ)
    aj   = a->j;
    aa   = a->a;
    fortranmultaij_(&m,x,ii,aj,aa,y);
#else

    // OpenACC starts here

    PetscInt xSize, ySize;

    ierr = VecGetLocalSize(xx, &xSize); CHKERRQ(ierr);
    ierr = VecGetLocalSize(yy, &ySize); CHKERRQ(ierr);

    ii = a->i;
    aj = a->j;
    aa = a->a;

    # pragma acc wait(1)
    # pragma acc enter data copyin(ii[:m+1]) async(1)
    # pragma acc enter data copyin(aj[:a->nz]) async(1)
    # pragma acc enter data copyin(aa[:a->nz]) async(1)

    # pragma acc enter data copyin(x[:xSize]) async(1)

    PetscInt present = 0;
    PetscInt current = 0;

    while((! acc_async_test_all()) && (current < m))
    {
      y[current] = single_row_mult(
              ii[current+1]-ii[current], aj+ii[current], aa+ii[current], x);
      current += 1;
    }

    int sizeBlock = 128 * 16 * 280;
    int nBlocks = (m - current) / sizeBlock;

    for(PetscInt b=0; b<nBlocks; ++b)
    {
      PetscInt bStart = current + b * sizeBlock;
      PetscInt bEnd = bStart + sizeBlock;
      PetscInt csrStart = ii[bStart];
      PetscInt csrSize = ii[bEnd] - csrStart;

      # pragma acc kernels loop independent gang vector(32) \
        present(ii[bStart:sizeBlock+1]) \
        present(aj[csrStart:csrSize]) \
        present(aa[csrStart:csrSize]) \
        present(x[:xSize]) \
        copyout(y[bStart:sizeBlock]) \
        async(b+1)
      for(PetscInt _i=bStart; _i<bEnd; ++_i)
        y[_i] = single_row_mult(ii[_i+1]-ii[_i], aj+ii[_i], aa+ii[_i], x);
    }

    if (((m - current) % sizeBlock) != 0)
    {
      PetscInt bStart = current + nBlocks * sizeBlock;
      sizeBlock = m - bStart;
      PetscInt csrStart = ii[bStart];
      PetscInt csrSize = ii[m] - csrStart;

      # pragma acc kernels loop independent gang vector(32) \
        present(ii[bStart:sizeBlock+1]) \
        present(aj[csrStart:csrSize]) \
        present(aa[csrStart:csrSize]) \
        present(x[:xSize]) \
        copyout(y[bStart:sizeBlock]) \
        async(nBlocks+1)
      for(PetscInt _i=bStart; _i<m; ++_i)
        y[_i] = single_row_mult(ii[_i+1]-ii[_i], aj+ii[_i], aa+ii[_i], x);
    }
    # pragma acc wait
    # pragma acc exit data delete(x[:xSize]) async
    // OpenACC ends here

#endif
  }
  ierr = PetscLogFlops(2.0*a->nz - a->nonzerorowcnt);CHKERRQ(ierr);
  ierr = VecRestoreArrayRead(xx,&x);CHKERRQ(ierr);
  ierr = VecRestoreArray(yy,&y);CHKERRQ(ierr);
  PetscFunctionReturn(0);
}

# pragma acc routine seq
PetscScalar single_row_mult(const PetscInt n, const PetscInt *cols, 
        const MatScalar *data, const PetscScalar *x)
{
    PetscScalar s = 0;

    for (PetscInt i=0; i<n; ++i)
        s += data[i] * x[cols[i]];

    return s;
}
