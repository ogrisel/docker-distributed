#!/bin/bash
exec su $BASICUSER -c "env PATH=$PATH dscheduler --host dscheduler --bokeh-whitelist 0.0.0.0 $*"
