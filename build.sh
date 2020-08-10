#!/bin/bash

# Set this variable according to the path of package on target
ROS2_PACKAGE_TARGET_INSTALL_PATH=/opt/ros/foxy

if [ ! -d "${QNX_TARGET}" ]; then
    echo "QNX_TARGET is not set. Exiting..."
    exit 1
fi

#for arch in armv7 aarch64 x86_64; do
for arch in aarch64; do

    if [ "${arch}" == "aarch64" ]; then
        CPUVARDIR=aarch64le
        CPUVAR=aarch64le
    elif [ "${arch}" == "armv7" ]; then
        CPUVARDIR=armle-v7
        CPUVAR=armv7le
    elif [ "${arch}" == "x86_64" ]; then
        CPUVARDIR=x86_64
        CPUVAR=x86_64
    else
        echo "Invalid architecture. Exiting..."
        exit 1
    fi

    echo "CPU set to ${CPUVAR}"
    echo "CPUVARDIR set to ${CPUVARDIR}"

    export CPUVARDIR=${CPUVARDIR}
    export CPUVAR=${CPUVAR}
    export ARCH=${arch}

    colcon --log-level 8 build --merge-install --cmake-force-configure \
        --build-base=build/${CPUVARDIR} \
        --install-base=install/${CPUVARDIR} \
        --cmake-args \
            -DCMAKE_TOOLCHAIN_FILE="${PWD}/platform/qnx.nto.toolchain.cmake" \
            -DCMAKE_VERBOSE_MAKEFILE:BOOL="ON" \
            -DBUILD_TESTING:BOOL="OFF" \
            -DCMAKE_BUILD_TYPE="Release" \
            -DTARGET_INSTALL_DIR="/opt/ros/foxy"

	# The three variables below are patched according to the installation of ros2 on target and the installation of the current package on target
    # Patching the scripts is done during the build process for convenience but can also be done on target if user chooses to do so
    # _colcon_prefix_chain_sh_COLCON_CURRENT_PREFIX --> package path on target
    # COLCON_CURRENT_PREFIX --> ros2 path on target
    # _colcon_prefix_sh_COLCON_CURRENT_PREFIX --> package path on target

    # setup.sh
    grep -rl "_colcon_prefix_chain_sh_COLCON_CURRENT_PREFIX=" install/${CPUVARDIR}/setup.sh | xargs sed -i "s|_colcon_prefix_chain_sh_COLCON_CURRENT_PREFIX=/.*$|_colcon_prefix_chain_sh_COLCON_CURRENT_PREFIX=${ROS2_PACKAGE_TARGET_INSTALL_PATH}|g"
    grep -rl "COLCON_CURRENT_PREFIX=\"/" install/${CPUVARDIR}/setup.sh | xargs sed -i 's|COLCON_CURRENT_PREFIX="/.*$|COLCON_CURRENT_PREFIX="/opt/ros/dashing"|g'
    # local_setup.sh
    grep -rl "_colcon_prefix_sh_COLCON_CURRENT_PREFIX=\"/" install/${CPUVARDIR}/local_setup.sh | xargs sed -i "s|_colcon_prefix_sh_COLCON_CURRENT_PREFIX=\"/.*\"|_colcon_prefix_sh_COLCON_CURRENT_PREFIX=\"${ROS2_PACKAGE_TARGET_INSTALL_PATH}\"|g"

done

exit 0
