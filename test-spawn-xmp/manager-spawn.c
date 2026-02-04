/* Code Example from http://mpi-forum.org/docs/mpi-2.0/mpi-20-html/node98.htm */
#include <stdio.h>
#include "mpi.h" 
int main(int argc, char *argv[]) 
{ 
  int world_size, universe_size, *universe_sizep, flag; 
  MPI_Comm everyone;           /* intercommunicator */ 
  char worker_program[100]; 
 
  MPI_Init(&argc, &argv); 
  MPI_Comm_size(MPI_COMM_WORLD, &world_size); 
 
  if (world_size != 1)    printf("Top heavy with management\n\n"); 
 
  MPI_Attr_get(MPI_COMM_WORLD, MPI_UNIVERSE_SIZE,  
	       &universe_sizep, &flag);  
  if (!flag) { 
    printf("This MPI does not support UNIVERSE_SIZE. \n How many processes total?"); 
    scanf("%d", &universe_size); 
  } else { 
    universe_size = *universe_sizep; 
    printf("Universe size = %d \n",universe_size);
  }
  if (universe_size == 1) printf("No room to start workers SO I SET IT TO 5 \n"); 
 
  /*  
   * Now spawn the workers. Note that there is a run-time determination 
   * of what type of worker to spawn, and presumably this calculation must 
   * be done at run time and cannot be calculated before starting 
   * the program. If everything is known when the application is  
   * first started, it is generally better to start them all at once 
   * in a single MPI_COMM_WORLD.  
   */ 
  universe_size=5;
  /* choose_worker_program(worker_program); */ 
  MPI_Comm_spawn("./worker_program", MPI_ARGV_NULL, universe_size-1,  
		 MPI_INFO_NULL, 0, MPI_COMM_SELF, &everyone,  
		 MPI_ERRCODES_IGNORE); 
  /* 
   * Parallel code here. The communicator "everyone" can be used 
   * to communicate with the spawned processes, which have ranks 0,.. 
   * MPI_UNIVERSE_SIZE-1 in the remote group of the intercommunicator 
   * "everyone". 
   */ 
 
  MPI_Finalize(); 
  return 0; 
}
