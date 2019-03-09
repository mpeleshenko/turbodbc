#!/bin/bash -ex

BOOST_VERSION=1.66.0
BOOST_VERSION_UNDERSCORE=${BOOST_VERSION//\./_}
NCORES=$(($(grep -c ^processor /proc/cpuinfo) + 1))

curl -sL https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz -o /boost_${BOOST_VERSION_UNDERSCORE}.tar.gz
tar xf boost_${BOOST_VERSION_UNDERSCORE}.tar.gz
mkdir /turbodbc_boost
pushd /boost_${BOOST_VERSION_UNDERSCORE}
./bootstrap.sh
./b2 -j${NCORES} tools/bcp
./dist/bin/bcp --namespace=turbodbc_boost --namespace-alias filesystem date_time system regex build algorithm locale format variant multiprecision/cpp_int /turbodbc_boost
popd

pushd /turbodbc_boost
ls -l
./bootstrap.sh
./bjam -j${NCORES} dll-path="'\$ORIGIN/'" cxxflags='-std=c++11 -fPIC' cflags=-fPIC linkflags="-std=c++11" variant=release link=shared --prefix=/turbodbc_boost_dist --with-filesystem --with-date_time --with-system --with-regex install
popd
rm -rf boost_${BOOST_VERSION_UNDERSCORE}.tar.gz boost_${BOOST_VERSION_UNDERSCORE} turbodbc_boost
# Boost always install header-only parts but they also take up quite some space.
# We don't need them, so don't persist them in the docker layer.
# fusion 16.7 MiB
rm -r /turbodbc_boost_dist/include/boost/fusion
# spirit 8.2 MiB
rm -r /turbodbc_boost_dist/include/boost/spirit
