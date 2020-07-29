#!/bin/bash

# Set this variable according to the path of package on target
ROS2_PACKAGE_TARGET_INSTALL_PATH=/opt/ros/foxy

# Set those variables according to the location of ROS2 Dependencies on host
ROS2_PYTHON_LIBS=$HOME/workspace/ros2/ros2_dashing/external/lib/python3.8/site-packages
ROS2_COLCON_PATH=$HOME/workspace/ros2/ros2_dashing/external/bin

if [ ! -d "$QNX_TARGET" ]; then
    echo "QNX_TARGET is not set. Exiting..."
    exit 1
fi

for arch in armv7 aarch64 x86_64; do

    if [ "$arch" == "aarch64" ]; then
        CPUVARDIR=aarch64le
        CPUVAR=${arch}le
    elif [ "$arch" == "armv7" ]; then
        CPUVARDIR=armle-v7
        CPUVAR=armv7le
    elif [ "$arch" == "x86_64" ]; then
        CPUVARDIR=$arch
        CPUVAR=$arch
    else
        echo "Invalid architecture. Exiting..."
        exit 1
    fi

    echo "CPU set to $CPUVAR"
    echo "CPUVARDIR set to $CPUVARDIR"

    FLAGS="-Wl,-rpath-link,$QNX_STAGE/$CPUVARDIR/usr/lib:$PWD/install/$CPUVARDIR/lib \
                -D__USESRCVERSION -D_QNX_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE \
                -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-variable -Wno-ignored-attributes \
                -I$QNX_STAGE/usr/include"

    LDFLAGS="-Wl,--build-id=md5"

    # ROS2 Dashing python host build tools
    EXPORT_CMD= export PYTHONPATH=$ROS2_PYTHON_LIBS:$PYTHONPATH && export PATH=$ROS2_COLCON_PATH:$PATH
    $EXPORT_CMD && colcon --log-level 8 build --merge-install --cmake-force-configure \
                    --build-base=build/$CPUVARDIR \
                    --install-base=install/$CPUVARDIR \
                    --cmake-args \
                        -DEXTRA_CMAKE_C_FLAGS="$FLAGS" \
                        -DEXTRA_CMAKE_CXX_FLAGS="$FLAGS -stdlib=libstdc++ -std=c++14" \
                        -DEXTRA_CMAKE_LINKER_FLAGS="$LDFLAGS -lstdc++" \
                        -DCPUVARDIR="$CPUVARDIR" \
                        -DCPUVAR="$CPUVAR" \
                        -DARCH="$arch" \
                        -DCMAKE_TOOLCHAIN_FILE="$PWD/platform/qnx.nto.toolchain.cmake" \
                        -DCMAKE_MAKE_PROGRAM="$QNX_HOST/usr/bin/make" \
                        -DGIT_EXECUTABLE="/usr/bin/git" \
                        -DPYTHON_EXECUTABLE="/usr/bin/python" \
                        -DPYTHON_LIBRARY="$QNX_TARGET/$CPUVARDIR/usr/lib/libpython3.8.so" \
                        -DPYTHON_INCLUDE_DIR="$QNX_TARGET/$CPUVARDIR/usr/include/python3.8:$QNX_TARGET/usr/include/python3.8:$QNX_STAGE/usr/include/python3.8" \
                        -DCMAKE_VERBOSE_MAKEFILE:BOOL="ON" \
                        -DBUILD_TESTING:BOOL="OFF" \
                        -DCMAKE_BUILD_TYPE="Release" \
                        -DTARGET_INSTALL_DIR="/opt/ros/foxy"

done

exit 0
