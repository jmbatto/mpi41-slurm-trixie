#!/bin/bash
set -e

# Socket variable declaration at the top for clarity/maintainability
SOCKET_PATH=/tmp/supervisor.sock 

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting the Slurm Database Daemon (slurmdbd) initialization..."
    
    # 1. SINGLE and PRECISE wait for the Supervisor socket.
    #    (Mandatory requirement for any subsequent `supervisorctl` calls)
    until [ -e "$SOCKET_PATH" ]; do
        echo "-- Waiting for Supervisor socket at $SOCKET_PATH. Sleeping..."
        sleep 1
    done
    echo "-- Supervisor socket is ready."

    # 2. Munge and DB Dependency Check
    #    (Note: The Munge process is already managed/started by Supervisor)
    echo "-- Giving Munged a moment to initialize its socket..."
    sleep 2
    
    {
        . /etc/slurm/slurmdbd.conf
        # Use --skip-ssl to bypass SSL requirements for the local DB client check
        until echo "SELECT 1" | mysql --skip-ssl -h $StorageHost -u$StorageUser -p$StoragePass 2>&1 > /dev/null
        do
            echo "-- Waiting for database to become active..."
            sleep 2
        done
    }
    echo "-- Database is now active."

    # --- ADDITION: CRITICAL RUNTIME DIRECTORY PREPARATION ---
    # These directories are volatile and may disappear upon restart.
    # We recreate them on-the-fly to prevent permission errors.
    echo "-- Ensuring runtime directories exist and belong to slurm..."
    mkdir -p /var/log/slurm /var/run/slurmdbd
    chown -R slurm:slurm /var/log/slurm /var/run/slurmdbd
    chmod 755 /var/log/slurm /var/run/slurmdbd
    # --------------------------------------------------------

    # 3. Daemon Launch and Health Verification
    echo "-- Starting slurmdbd via Supervisor..."
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start slurmdbd
    
    # CRITICAL: Wait and verify that the daemon actually started.
    sleep 5 # Grace period: Allow slurmdbd time to fail if Munge/Permission issues exist.
    
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf status slurmdbd | grep -q 'RUNNING'
    if [ $? -ne 0 ]; then
        echo "FATAL ERROR: slurmdbd failed to enter RUNNING state. Check logs in /tmp/slurmdbd.err."
        exit 1 # Fail-fast: Force container exit if slurmdbd is not running.
    fi

fi

# ----------------------------------------------------------------------
# slurmctld and slurmd blocks (Logic simplified: Socket wait + Port check)
# ----------------------------------------------------------------------

if [ "$1" = "slurmctld" ]
then
    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."
    
    # Ensure Supervisor is ready to accept commands
    until [ -e "$SOCKET_PATH" ]; do
        sleep 1
    done
    
    # Network dependency check: Wait for SlurmDBD port (6819)
    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available. Sleeping ..."
        sleep 2
    done
    
    echo "-- slurmdbd is now active, starting slurmctld via Supervisor..."
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start slurmctld
    
fi


if [ "$1" = "slurmd" ]
then
    echo "---> Waiting for slurmctld to become active before starting slurmd..."
    
    # Ensure Supervisor is ready to accept commands
    until [ -e "$SOCKET_PATH" ]; do
        sleep 1
    done
    
    # Network dependency check: Wait for SlurmCTLD port (6817)
    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available. Sleeping ..."
        sleep 2
    done
    
    echo "-- slurmctld is now active, starting slurmd via Supervisor..."
    supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start slurmd
fi