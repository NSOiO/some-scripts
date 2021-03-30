#!/bin/sh
#Usage:
    # export PROJECT_NAME="proj-name"
    # export SRCROOT="./"
    # export CF_CUS_PRODUDT_NAME="universal/Products"

    # sh compile_framework.sh target-name

# remove arm64 from simulator library if exist.
function removeArchFrom() {
    local file=$1
    local need_remove=$2
    local archs=$(lipo -archs $file)

    for arch in $archs 
    do 
        if [ $arch == $need_remove ];
        then 
            lipo $file -remove $arch -output $file
        fi 
    done
}

# Sets the target folders and the final framework product.
CUS_TARGET_NAME=$1
FMK_NAME=${CUS_TARGET_NAME:-${PROJECT_NAME}}

CUS_PRODUDT_NAME=$CF_CUS_PRODUDT_NAME
CUS_PRODUDT_NAME=${CF_CUS_PRODUDT_NAME:-"Products"}
CUS_SIM_ARCH=${CF_CUS_SIM_ARCH}

FMK_BUNDLE=${SRCROOT}/${FMK_NAME}/${FMK_NAME}.bundle
# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
INSTALL_DIR=${SRCROOT}/${CUS_PRODUDT_NAME}/${FMK_NAME}.framework
BUNDLE_DIR=${SRCROOT}/${CUS_PRODUDT_NAME}/${FMK_NAME}.bundle
# Working dir will be deleted after the framework creation.
WRK_DIR=build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework
# -configuration ${CONFIGURATION}
# Clean and Building both architectures.
xcodebuild clean
xcodebuild OTHER_CFLAGS="-fembed-bitcode" -configuration "Release" -target "${FMK_NAME}" -sdk iphoneos
xcodebuild OTHER_CFLAGS="-fembed-bitcode" ${CUS_SIM_ARCH} -configuration "Release" -target "${FMK_NAME}" -sdk iphonesimulator
# Cleaning the oldest.
if [ -d "${INSTALL_DIR}" ]; then
    rm -rf "${INSTALL_DIR}"
fi
# Copy device lib
mkdir -p "${INSTALL_DIR}"
cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}/"

# Cleaning the oldest.
if [ -d "${BUNDLE_DIR}" ]; then
    rm -rf "${BUNDLE_DIR}"
fi
# Copy bundle
if [ -d "${FMK_BUNDLE}" ]; then
    mkdir -p "${BUNDLE_DIR}"
    cp -R "${FMK_BUNDLE}/" "${BUNDLE_DIR}/"
fi
# Remove arm64 from simulator lib
removeArchFrom "${SIMULATOR_DIR}/${FMK_NAME}" "arm64"
# Uses the Lipo Tool to merge both binary files (i386/x86_64 + armv7/arm64) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/${FMK_NAME}"
# Remove build dir
rm -r "${WRK_DIR}"

# FMK_OUTPUT_CLEAR="${INSTALL_DIR}/_CodeSignature"
# if [ -d "${FMK_OUTPUT_CLEAR}" ]; then
#     rm -rf "${FMK_OUTPUT_CLEAR}"
# fi

# Whether to open final dir
if [ $2 ]; then
    open "${INSTALL_DIR}/../"
fi
