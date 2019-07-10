#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
STDOUT=/dev/null
STDERR=/dev/null
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
    STDOUT='/dev/stdout'
    STDERR='/dev/stderr'
fi
set -e                          # Abort on errors



# Set locations
THORN=NSIMD
NAME=nsimd-2.2
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

echo "NSIMD: Configuring..."
cd ${NAME}
mkdir build
cd build

# a mini-configure script, not sure how else to do this
function NSIMD_TRY_COMPILE() {
  local TEST="$1"
  mkdir -p autoconfig
  pushd autoconfig >/dev/null
  tee >${STDOUT} conftest.c <<EOF
  #if(!($TEST))
  #error "$TEST not present"
  #else
  int a;
  #endif
EOF
  ${CC} >${STDOUT} 2>${STDERR} ${CFLAGS} -c conftest.c
  local RC=$?
  popd >/dev/null
  return $RC
}
if [ "x${NSIMD_SIMD}" = "xauto" ] ; then
    if NSIMD_TRY_COMPILE "defined(__AVX512ER__)" ; then
      NSIMD_SIMD="AVX512_KNL"
    elif NSIMD_TRY_COMPILE "defined(__AVX512F__)" ; then
      NSIMD_SIMD= "AVX512_SKYLAKE"
    elif NSIMD_TRY_COMPILE "defined(__AVX2__)" ; then
        NSIMD_SIMD="AVX2"
    elif NSIMD_TRY_COMPILE "defined(__AVX__)" ; then
        NSIMD_SIMD="AVX"
    elif NSIMD_TRY_COMPILE "defined(__SSE4_2__)" ; then
        NSIMD_SIMD="SSE42"
    elif NSIMD_TRY_COMPILE "defined(__SSE4_1__)" ; then
        NSIMD_SIMD="SSE41"
    elif NSIMD_TRY_COMPILE "defined(__SSE3__)" ; then
        NSIMD_SIMD="SSE3"
    elif NSIMD_TRY_COMPILE "defined(__SSE2__)" ; then
        NSIMD_SIMD="SSE2"
    elif NSIMD_TRY_COMPILE "defined(__SSE__)" ; then
        NSIMD_SIMD="SSE"
    else
        NSIMD_SIMD="CPU"
    fi
    # TODO: add checks for non-x86 architectures
fi
rm -rf autoconfig

cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_CXX_COMPILER=${CXX} -Dsimd=${NSIMD_SIMD} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ..

echo "NSIMD: Building..."
${MAKE}

echo "NSIMD: Installing..."
${MAKE} install
popd >/dev/null

echo "NSIMD: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "NSIMD: Done."
