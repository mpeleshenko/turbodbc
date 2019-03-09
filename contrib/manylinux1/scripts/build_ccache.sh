#!/bin/bash -ex

curl -sL https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.bz2 -o ccache-3.3.4.tar.bz2
tar xf ccache-3.3.4.tar.bz2
pushd ccache-3.3.4
./configure --prefix=/usr
make -j5
make install
popd
rm -rf ccache-3.3.4.tar.bz2 ccache-3.3.4

# Initialize the config directory, otherwise the build sometimes fails.
mkdir /root/.ccache
