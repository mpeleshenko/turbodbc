#!/bin/bash -e
# Build upon the scripts in https://github.com/matthew-brett/manylinux-builds
# * Copyright (c) 2013-2016, Matt Terry and Matthew Brett (BSD 2-clause)

PYTHON_VERSIONS="${PYTHON_VERSIONS:-2.7,16 2.7,32 3.5,16 3.6,16, 3.7,16}"

source /multibuild/manylinux_utils.sh

for PYTHON_TUPLE in ${PYTHON_VERSIONS}; do
    IFS=","
    set -- $PYTHON_TUPLE;
    PYTHON=$1
    U_WIDTH=$2
    PYTHON_INTERPRETER="$(cpython_path $PYTHON ${U_WIDTH})/bin/python"
    PIP="$(cpython_path $PYTHON ${U_WIDTH})/bin/pip"
    PATH="$PATH:$(cpython_path $PYTHON ${U_WIDTH})"

    echo "=== (${PYTHON}, ${U_WIDTH}) Installing build dependencies ==="
    $PIP install "numpy==1.14.5" "pyarrow==0.12.1" "virtualenv==16.3.0"

    echo "=== (${PYTHON}, ${U_WIDTH}) Preparing virtualenv for tests ==="
    "$(cpython_path $PYTHON ${U_WIDTH})/bin/virtualenv" -p ${PYTHON_INTERPRETER} --no-download /venv-test-${PYTHON}-${U_WIDTH}
    source /venv-test-${PYTHON}-${U_WIDTH}/bin/activate
    pip install pytest hypothesis 'numpy==1.14.5' 'pyarrow==0.12.1'
    deactivate
done

# Remove debug symbols from libraries that were installed via wheel.
find /venv-test-*/lib/*/site-packages/pyarrow -name '*.so' -exec strip '{}' ';'
find /venv-test-*/lib/*/site-packages/numpy -name '*.so' -exec strip '{}' ';'
# Only Python 3.6+ packages are stripable as they are built inside of the image
find /opt/_internal/cpython-3.6.*/lib/python3.6/site-packages/numpy -name '*.so' -exec strip '{}' ';'
find /opt/_internal/cpython-3.7.*/lib/python3.7/site-packages/numpy -name '*.so' -exec strip '{}' ';'

# Remove pip cache again. It's useful during the virtualenv creation but we
# don't want it persisted in the docker layer, ~264MiB
rm -rf /root/.cache
