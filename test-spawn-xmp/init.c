#include <stdio.h>
#include "Matrix.xmptype.h"

#pragma xmp nodes p(2,2)
#pragma xmp template t(0:3,0:3)
#pragma xmp distribute t(block,block) onto p

XMP_Matrix A[4][4];
#pragma xmp align A[i][j] with t(j,i)

XMP_Matrix B[4][4];
#pragma xmp align B[i][j] with t(j,i)

XMP_Matrix C[4][4];
#pragma xmp align C[i][j] with t(j,i)

int main(int argc, char ** argv){
  int rank;
  MPI_Barrier(MPI_COMM_WORLD);
  MPI_Comm_rank(MPI_COMM_WORLD,&rank);
  int i,j,n;
  n=4;
  fprintf(stderr,"rank = %d ; ",rank);

  #pragma xmp loop (i,j) on t(j,i)
  for (i=0;i<n;i++){
    for(j=0;j<n;j++){
      fprintf(stderr,"\n(%d, %d, %d) ",rank,i,j);
      C[i][j] = 0;
      A[i][j] = 1;
      B[i][j] = i*n+j+1;
    }
  }
  MPI_Barrier(MPI_COMM_WORLD);
}
  
  
