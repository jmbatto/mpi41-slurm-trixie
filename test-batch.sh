#!/bin/bash
#SBATCH --job-name=test_mpi       # Job name
#SBATCH --partition=docker        # Partition name (defined in your slurm.conf)
#SBATCH --nodes=2                 # Request 2 nodes (c1 and c2)
#SBATCH --ntasks=2                # Request 2 tasks in total
#SBATCH --ntasks-per-node=1       # 1 task per node (to force distribution across containers)
#SBATCH --output=res_%j.out       # Standard output file (%j = Job ID)
#SBATCH --error=res_%j.err        # Error file

echo "=========================================="
echo "SLURM Job ID: $SLURM_JOB_ID"
echo "Start Date: $(date)"
echo "Executed on master node: $(hostname)"
echo "List of allocated nodes: $SLURM_JOB_NODELIST"
echo "=========================================="

echo ""
echo ">>> TEST 1: Simple node verification (srun hostname)"
# Should return c1 and c2 (based on your docker-compose service names)
srun hostname

echo ""
echo ">>> TEST 2: MPI Test via Python (mpi4py)"
# This Python script will display the MPI rank and hostname
# Since your Docker image uses MpiDefault=pmi2, srun handles the bootstrapping
srun python3 -c "from mpi4py import MPI; \
comm = MPI.COMM_WORLD; \
rank = comm.Get_rank(); \
size = comm.Get_size(); \
host = MPI.Get_processor_name(); \
print(f'MPI SUCCESS: I am rank {rank} of {size}, running on container {host}')"

echo ""
echo "=========================================="
echo "Job finished: $(date)"