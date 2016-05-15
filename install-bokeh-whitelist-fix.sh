#!/bin/bash
# Patch bokeh to fix:
# https://github.com/bokeh/bokeh/issues/4325
set -xe

pushd /work/miniconda/lib/python3.5/site-packages/
patch -p1 < /work/bokeh-0.11.1-fix-4325.diff
popd
