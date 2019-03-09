#!/bin/bash -e

/opt/python/cp35-cp35m/bin/pip install cmake ninja
ln -s /opt/python/cp35-cp35m/bin/cmake /usr/bin/cmake
ln -s /opt/python/cp35-cp35m/bin/ninja /usr/bin/ninja
strip /opt/_internal/cpython-3.*/lib/python3.5/site-packages/cmake/data/bin/*
