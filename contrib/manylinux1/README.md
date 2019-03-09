## Manylinux1 wheels for Turbodbc

This folder provides base Docker images and an infrastructure to build
`manylinux1` compatible Python wheels that should be installable on all
Linux distributions published in last four years.

The process is split up in two parts: There are base Docker images that build
the native, Python-indenpendent dependencies. Depending on these images, there
is also a bash script that will build the turbodbc wheels for all supported
Python versions and place them in the `dist` folder.

### Build instructions

You can build the wheels with the following
command (this is for Python 2.7 with unicode width 16, similarly you can pass
in `PYTHON_VERSION="3.5"`, `PYTHON_VERSION="3.6"` or `PYTHON_VERSION="3.7"` or
use `PYTHON_VERSION="2.7"` with `UNICODE_WIDTH=32`):

```bash
# Build the python packages
docker run --env PYTHON_VERSION="2.7" --env UNICODE_WIDTH=16 --shm-size=2g --rm -t -i -v $PWD:/io -v $PWD/../../:/turbodbc quay.io/xhochy/turbodbc_manylinux1_x86_64_base:latest /io/build_turbodbc.sh
# Now the new packages are located in the dist/ folder
ls -l dist/
```

### Updating the build environment
The base docker image is less often updated. In the case we want to update
a dependency to a new version, we also need to adjust it. You can rebuild
this image using

```bash
docker build -t turbodbc_manylinux1_x86_64_base -f Dockerfile-x86_64_base .
```

For each dependency, we have a bash script in the directory `scripts/` that
downloads the sources, builds and installs them. At the end of each dependency
build the sources are removed again so that only the binary installation of a
dependency is persisted in the docker image. When you do local adjustments to
this image, you need to change the name of the docker image in the `docker run`
command.

### Using quay.io to trigger and build the docker image

1.  Make the change in the build scripts (eg. to modify the boost build, update `scripts/boost.sh`).

2.  Setup an account on quay.io and link to your GitHub account

3.  In quay.io,  Add a new repository using :

    1.  Link to GitHub repository push
    2.  Trigger build on changes to a specific branch (eg. myquay) of the repo (eg. `mpeleshenko/turbodbc`)
    3.  Set Dockerfile location to `/manylinux1/Dockerfile-x86_64_base`
    4.  Set Context location to `/manylinux1`

4.  Push change (in step 1) to the branch specified in step 3.ii

    *  This should trigger a build in quay.io, the build takes about 2 hrs to finish.

5.  Add a tag `latest` to the build after step 4 finishes, save the build ID (eg. `quay.io/mpeleshenko/turbodbc_manylinux1_x86_64_base:latest`)

6.  In your turbodbc PR,

    *  include the change from 1.
    *  modify `travis_script_manylinux.sh` to switch to the location from step 5 for the docker image.
