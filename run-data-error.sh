#!/bin/bash
set -e
set -x

LPINAME=fipq

function buildmode {
    LPINAME=$1
    MODE=$2
    echo
    echo building $LPINAME $MODE ...
    rm -rf lib/
    WD=$(pwd)
    if [ -d "/c/Ultibo/Core" ]; then
	LAZDIR=/c/Ultibo/Core
    fi
    if [ -d "$HOME/ultibo/core" ]; then
	LAZDIR="$HOME/ultibo/core"
    fi
    pushd $LAZDIR >& /dev/null
    rm -f kernel*.img kernel.bin
    ./lazbuild --build-mode=BUILD_MODE_$MODE $WD/$LPINAME.lpi # >& errors.txt
    popd >& /dev/null
    mv kernel* $LPINAME-kernel-${MODE,,}.img
}

buildmode $LPINAME QEMUVPB

qemu-system-arm -machine versatilepb -cpu cortex-a8 -m 256M        \
    -drive file=fipq/ultibo.img,if=sd,format=raw                   \
    -kernel $LPINAME-kernel-qemuvpb.img                            \
    -serial stdio                                                  \
    -display none                                                  \
    -append ""
