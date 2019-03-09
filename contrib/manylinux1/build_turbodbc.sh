#!/bin/bash

source /multibuild/manylinux_utils.sh

# Quit on failure
set -e

# Print commands for debugging
set -x

cd /turbodbc

# Turbodbc build configuration
export TURBODBC_BUILD_TYPE='release'
export TURBODBC_CMAKE_GENERATOR='Ninja'
export TURBODBC_BUNDLE_BOOST=1
export TURBODBC_BOOST_NAMESPACE=turbodbc_boost
export PKG_CONFIG_PATH=/turbodbc-dist/lib/pkgconfig

export TURBODBC_CMAKE_OPTIONS='-DBoost_NAMESPACE=${TURBODBC_BOOST_NAMESPACE} -DBOOST_ROOT=/${TURBODBC_BOOST_NAMESPACE}_dist'
# Ensure the target directory exists
mkdir -p /io/dist

# Must pass PYTHON_VERSION and UNICODE_WIDTH env variables
# possible values are: 2.7,16 2.7,32 3.5,16 3.6,16 3.7,16

CPYTHON_PATH="$(cpython_path ${PYTHON_VERSION} ${UNICODE_WIDTH})"
PYTHON_INTERPRETER="${CPYTHON_PATH}/bin/python"
PIP="${CPYTHON_PATH}/bin/pip"
PATH="${PATH}:${CPYTHON_PATH}"

echo "=== (${PYTHON_VERSION}) Building Turbodbc C++ libraries ==="
TURBODBC_BUILD_DIR=/tmp/build-PY${PYTHON_VERSION}-${UNICODE_WIDTH}
mkdir -p "${TURBODBC_BUILD_DIR}"
pushd "${TURBODBC_BUILD_DIR}"
PATH="${CPYTHON_PATH}/bin:${PATH}" cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/turbodbc-dist \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DTURBODBC_BUILD_TESTS=OFF \
    -DTURBODBC_BUILD_SHARED=ON \
    -DTURBODBC_BOOST_USE_SHARED=ON \
    -DTURBODBC_RPATH_ORIGIN=ON \
    -DTURBODBC_PYTHON=ON \
    -DPythonInterp_FIND_VERSION=${PYTHON_VERSION} \
    -DBoost_NAMESPACE=${TURBODBC_BOOST_NAMESPACE} \
    -DBOOST_ROOT=/${TURBODBC_BOOST_NAMESPACE}_dist \
    -GNinja /turbodbc/cpp
ninja install
popd

echo "=== (${PYTHON_VERSION}) Install the wheel build dependencies ==="
$PIP install -r requirements-wheel.txt

# Clear output directory
rm -rf dist/
echo "=== (${PYTHON_VERSION}) Building wheel ==="
# Remove build directory to ensure CMake gets a clean run
rm -rf build/
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py build_ext \
    --inplace \
    --bundle-boost \
    --boost-namespace=${TURBODBC_BOOST_NAMESPACE}
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py bdist_wheel
PATH="$PATH:${CPYTHON_PATH}/bin" $PYTHON_INTERPRETER setup.py sdist

if [ -n "$UBUNTU_WHEELS" ]; then
  echo "=== (${PYTHON_VERSION}) Wheels are not compatible with manylinux1 ==="
  mv dist/turbodbc-*.whl /io/dist
else
  echo "=== (${PYTHON_VERSION}) Tag the wheel with manylinux1 ==="
  mkdir -p repaired_wheels/
  auditwheel -v repair -L . dist/turbodbc-*.whl -w repaired_wheels/

  # Install the built wheels
  $PIP install repaired_wheels/*.whl

  # Test that the modules are importable
  $PYTHON_INTERPRETER -c "
import sys
import turbodbc
import turbodbc_numpy_support
import turbodbc_arrow_support
  "

  # More thorough testing happens outsite of the build to prevent
  # packaging issues like ARROW-4372
  mv dist/*.tar.gz /io/dist
  mv repaired_wheels/*.whl /io/dist
fi
