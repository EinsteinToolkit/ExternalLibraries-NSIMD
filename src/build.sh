#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



# Set locations
THORN=NSIMD
NAME=nsimd-3.0.1
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${NSIMD_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "Installing NSIMD into ${NSIMD_INSTALL_DIR}"
    INSTALL_DIR=${NSIMD_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
NSIMD_DIR=${INSTALL_DIR}

echo "NSIMD: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

# Build core library
echo "NSIMD: Unpacking archive..."
pushd ${BUILD_DIR} >/dev/null
${TAR?} xf ${SRCDIR}/../dist/${NAME}.tar
pushd ${NAME}
${PATCH?} -p1 < ${SRCDIR}/../dist/version.patch
${PATCH?} -p1 < ${SRCDIR}/../dist/sleef_zip.patch
# Some (ancient but still used) versions of patch don't support the
# patch format used here but also don't report an error using the exit
# code. So we use this patch to test for this
${PATCH?} -p1 < ${SRCDIR}/../dist/patchtest.patch
if [ ! -e .patch_tmp ]; then
    echo 'BEGIN ERROR'
    echo 'The version of patch is too old to understand this patch format.'
    echo 'Please set the PATCH environment variable to a more recent '
    echo 'version of the patch command.'
    echo 'END ERROR'
    exit 1
fi
rm -f .patch_tmp
popd

echo "NSIMD: Configuring..."
cd ${NAME}
mkdir build
cd build

unset LIBS
export SRCDIR # needed to find sleef.zip

${CMAKE_DIR:+${CMAKE_DIR}/bin/}cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_CXX_COMPILER=${CXX} -Dsimd=${NSIMD_SIMD} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ..

echo "NSIMD: Building..."
${MAKE}

echo "NSIMD: Installing..."
${MAKE} install
popd >/dev/null

echo "NSIMD: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "NSIMD: Done."
