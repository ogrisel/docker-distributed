#!/bin/bash
NCPUS=`python -c "import multiprocessing as mp; print(mp.cpu_count())"`
echo "Detected $NCPUS cpus"
exec su $BASICUSER -c "env PATH=$PATH dworker dscheduler:8786 --nthreads 1 --nprocs $NCPUS $*"
