#!/bin/bash
exec su $BASICUSER -c "env PATH=$PATH dworker dscheduler:8786 $*"
