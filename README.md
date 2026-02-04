# mpi41-slurm-trixie
A complete, self-contained High-Performance Computing (HPC) simulation environment based on Debian Trixie (Testing). It is designed to emulate a computing cluster with a job scheduler, parallel programming libraries, and performance monitoring tools.

The image is intended to be orchestrated via Docker Swarm or Docker Compose to create a multi-node cluster architecture (Head node + Compute nodes).
Key Components & Features

    Base System: Debian Trixie-slim with essential build tools (gcc, g++, cmake, gfortran) and system utilities (sudo, ssh, vim, neowofetch).

    MPI Implementation:

        OpenMPI 4.1.8: Compiled from source with custom MCA parameters optimized for containerized TCP communication.

        Python Integration: Includes a Python 3 virtual environment (/opt/venv) with mpi4py installed.

    Job Scheduler:

        Slurm Workload Manager (v23.02): Compiled from source. Includes configuration for slurmctld (controller) and slurmdbd (database).

        Includes Munge authentication for secure communication between nodes.

    XcalableMP Support:

        Omni Compiler 1.3.4: Installed to support XcalableMP (XMP), a directive-based parallel programming language.

    Monitoring:

        Telegraf: Pre-installed agent to collect performance metrics, configured to work with an InfluxDB/Grafana stack.

    Process Management: Uses supervisord as the entrypoint to manage multiple daemons (SSHD, etc.) simultaneously.

User Configuration

    User: Runs under a non-root user mpiuser (UID 1001) with sudo privileges.

    SSH: A custom SSHD configuration runs in user space (non-privileged) to facilitate MPI communication between containers using RSA keys managed via Docker Secrets.

Architecture (Docker Compose)

This image is designed to act as both the Head Node (mpihead) and Compute Nodes (mpinode). When deployed with the accompanying compose file:

    Nodes communicate via an overlay network (mpinet).

    SSH keys are injected securely via Docker Secrets.

    The cluster is monitored by a sidecar Grafana/InfluxDB service.


# SSH Key Generation Procedure

To run the cluster, you must generate a dedicated RSA key pair. These keys allow the MPI Head Node and Compute Nodes to communicate securely without password prompts.
1. Create the local directory

Ensure you are in the root directory of the project (where docker-compose.yml is located) and create the ssh folder:
Bash

mkdir -p ssh

2. Generate the Key Pair

Run the following command to generate a 4096-bit RSA key pair. Crucial: We use -N "" to set an empty passphrase. This is required for MPI jobs to launch automatically without user intervention.
Bash

ssh-keygen -t rsa -b 4096 -f ./ssh/id_rsa.mpi -q -N ""

Command explanation:

    -t rsa: Specifies the key type (RSA).

    -b 4096: Specifies the key complexity (bits).

    -f ./ssh/id_rsa.mpi: Forces the filename to match the docker-compose.yml requirement.

    -q: Silence the output (quiet mode).

    -N "": Sets an empty password (essential for automated MPI tasks).

3. Verify the files

Check that the ssh directory now contains the two required files:
Bash

ls -l ssh/
# Output should show:
# id_rsa.mpi       (Private Key)
# id_rsa.mpi.pub   (Public Key)

4. Security Recommendation (Git)

Since these keys grant access to your cluster, ensure they are ignored by version control. Add the following line to your .gitignore file:
Plaintext

ssh/

Why is this necessary?

Your docker-compose.yml is configured to inject these specific files as Docker Secrets:
YAML

secrets:
  id_rsa_mpi_pub:
    file: ssh/id_rsa.mpi.pub
  id_rsa:
    file: ssh/id_rsa.mpi

If these files are missing or named differently, the container deployment will fail.
