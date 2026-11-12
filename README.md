# mpi41-slurm-trixie

A two-node HPC cluster simulation on Debian Trixie. One controller, one accounting database, two compute nodes. Slurm, OpenMPI, MUNGE, and a monitoring stack are installed and configured. The containers are hardened so a process inside cannot escape to the Docker daemon on the host.

The lab has been used with students who wanted to try XcalableMP without access to a real machine.

## Ambition

The image is a functional lab, not a demo of a single process. Bring it up with the compose file and you have:

- a Slurm controller (`slurmctld`) and an accounting daemon (`slurmdbd`)
- two compute nodes (`c1`, `c2`) running `slurmd`
- OpenMPI 4.1.8 with a Python environment (`mpi4py`)
- MUNGE for Slurm authentication
- Telegraf feeding an InfluxDB/Grafana side-car

Jobs run as a normal user. The cluster is small on purpose. Two nodes are enough to exercise scheduling, accounting, and multi-node MPI without the cost of a real machine.

## What is installed

| Component | Role |
| --- | --- |
| Debian Trixie-slim | base |
| Slurm 23.02 | controller, database daemon, compute daemons |
| OpenMPI 4.1.8 | compiled with PMI support for `srun` |
| PMI2 / PMIx | process management interface used by Slurm |
| mpi4py | in `/opt/venv` |
| Omni Compiler 1.3.4 | XcalableMP |
| MUNGE | authentication between Slurm daemons |
| Telegraf | metrics to InfluxDB |
| supervisord | process supervision inside the image |

User `mpiuser` is uid 1001. SSH keys are injected as Docker secrets, not baked into the image.

### Tools in the image

The Dockerfile pulls a working set for a practical session:

- compilers: `gcc`, `g++`, `gfortran`
- build: `cmake`, `autoconf`, `automake`, `libtool`, `make`
- debug: `gdb`, `strace`, `binutils`
- editors: `vim`, `emacs`, `nano`
- network: `iputils-ping`, `netcat`, `dnsutils`, `curl`
- convenience: `jq`, `colordiff`, `neowofetch`, `bash-completion`

OpenMPI is configured with `--with-pmi` so that `srun` can launch MPI jobs. The MCA parameters favour TCP on the container interface.

## PMI2

Slurm is set with `MpiDefault=pmi2`. Jobs must use PMI2, not the OpenMPI default launcher.

```bash
srun --mpi=pmi2 -n 2 ./myprog
```

Or in a batch script:

```bash
#!/bin/bash
#SBATCH -n 2
srun --mpi=pmi2 ./myprog
```

Without `--mpi=pmi2`, `srun` does not wire the PMI handshake and the job fails or hangs. `mpirun` alone bypasses Slurm placement. Prefer `srun --mpi=pmi2`.

## Security boundary

The design goal is that a process inside a container cannot reach the Docker daemon or the accounting database except through the path that is meant for it.

- `cap_drop: ALL` on every service. Capabilities are added back only for the role (bind, setuid, nice, ptrace on compute).
- `no-new-privileges: true`.
- The Docker socket is not mounted. Nothing in the cluster can talk to the host daemon.
- MySQL is on a dedicated internal network (`dbnet`). Only `slurmdbd` is attached to it. Compute nodes and the controller cannot resolve or reach the database.
- SSH private keys arrive as secrets. They are not in the image layers.
- MUNGE key lives in a volume owned by the `munge` user, mode 400.

These measures do not make the cluster a multi-tenant production system. They make the lab honest: an agent or a job that runs inside sees the cluster, not the host.

## Architecture

```
mpinet
├── slurmctld     controller
├── slurmdbd      accounting  ──also──  dbnet (internal)
├── c1            compute
├── c2            compute
└── grafana       metrics

dbnet (internal)
└── mysql         only slurmdbd reaches it
```

`mpinet` is the cluster network. `dbnet` has `internal: true`. No route out of it.

## Bring it up

Generate the SSH key pair the compose expects:

```bash
mkdir -p ssh
ssh-keygen -t rsa -b 4096 -f ./ssh/id_rsa.mpi -q -N ""
```

Add `ssh/` to `.gitignore`. Then:

```bash
docker compose up -d
```

Check the nodes:

```bash
docker exec slurmctld sinfo
docker exec slurmctld squeue
```

## XcalableMP

Omni Compiler is installed under `/usr/local`. A small spawn test is copied into `/home/mpiuser/YMLEnvironment/test-spawn-xmp`. Students can compile and run an XMP program with `srun --mpi=pmi2` the same way as a plain MPI binary.

## Limits

- Resource limits (cgroup) are declarative. The image does not hold `CAP_SYS_ADMIN`, so enforcement is not active.
- Jobs submitted as root arrive as root on the compute nodes. Prefer `mpiuser`.
- This is a simulation. It is not a substitute for a real HPC allocation.

## Related

- LiteIDE plugin that drives a Cline companion against this cluster: [agentplurai](https://github.com/jmbatto/agentplurai)
- Cline node derived from this image: [companion-cline](https://github.com/jmbatto/agentplurai/tree/main/companion-cline)
