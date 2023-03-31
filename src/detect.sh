#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

# Take care of requests to build the library in any case
NSIMD_DIR_INPUT=$NSIMD_DIR
if [ "$(echo "${NSIMD_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    NSIMD_BUILD=1
    NSIMD_DIR=
else
    NSIMD_BUILD=
fi

# default values if unset
if [ -z "${NSIMD_SIMD:+set}" ] ; then
    NSIMD_SIMD="CPU"
fi


################################################################################
# Decide which libraries to link with
################################################################################

# Set up names of the libraries based on configuration variables. Also
# assign default values to variables.
# Try to find the library if build isn't explicitly requested
if [ -z "${NSIMD_BUILD}" -a -z "${NSIMD_INC_DIRS}" -a -z "${NSIMD_LIB_DIRS}" -a -z "${NSIMD_LIBS}" ]; then
    find_lib NSIMD nsimd 1 1.0 "nsimd_${NSIMD_SIMD}" "nsimd/nsimd.h" "$NSIMD_DIR"
fi

THORN=NSIMD

# configure library if build was requested or is needed (no usable
# library found)
if [ -n "$NSIMD_BUILD" -o -z "${NSIMD_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Using bundled NSIMD..."
    echo "END MESSAGE"
    NSIMD_BUILD=1

    check_tools "tar patch"
    
    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${NSIMD_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing NSIMD into ${NSIMD_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${NSIMD_INSTALL_DIR}
    fi
    NSIMD_DIR=${INSTALL_DIR}
    # Fortran modules may be located in the lib directory
    NSIMD_INC_DIRS="${NSIMD_DIR}/include ${NSIMD_DIR}/lib"
    NSIMD_LIB_DIRS="${NSIMD_DIR}/lib"
    # name needs to be known at configure time, so autoconf at build is
    # impossible
    NSIMD_LIBS="nsimd_${NSIMD_SIMD}"
else
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi

if [ -n "$NSIMD_DIR" ]; then
    : ${NSIMD_RAW_LIB_DIRS:="$NSIMD_LIB_DIRS"}
    # Fortran modules may be located in the lib directory
    NSIMD_INC_DIRS="$NSIMD_RAW_LIB_DIRS $NSIMD_INC_DIRS"
    # We need the un-scrubbed inc dirs to look for a header file below.
    : ${NSIMD_RAW_INC_DIRS:="$NSIMD_INC_DIRS"}
else
    echo 'BEGIN ERROR'
    echo 'ERROR in NSIMD configuration: Could neither find nor build library.'
    echo 'END ERROR'
    exit 1
fi

################################################################################
# Check for additional libraries
################################################################################



################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "NSIMD_BUILD          = ${NSIMD_BUILD}"
echo "NSIMD_INSTALL_DIR    = ${NSIMD_INSTALL_DIR}"
echo "NSIMD_SIMD           = ${NSIMD_SIMD}"
echo "NSIMD_OPTIONALS      = ${NSIMD_OPTIONALS}"
echo "END MAKE_DEFINITION"

# Pass compiler options to Cactus
echo "BEGIN DEFINE"
echo "NSIMD_${NSIMD_SIMD}"
echo "END DEFINE"

# Pass linker options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "NSIMD_DIR            = ${NSIMD_DIR}"
echo "NSIMD_INC_DIRS       = ${NSIMD_INC_DIRS}"
echo "NSIMD_LIB_DIRS       = ${NSIMD_LIB_DIRS}"
echo "NSIMD_LIBS           = ${NSIMD_LIBS}"
echo "NSIMD_SIMD           = ${NSIMD_SIMD}"
echo "NSIMD_OPTIONALS      = ${NSIMD_OPTIONALS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(NSIMD_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(NSIMD_LIB_DIRS)'
echo 'LIBRARY           $(NSIMD_LIBS)'
