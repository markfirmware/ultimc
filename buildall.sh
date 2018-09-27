#!/bin/bash
set -e

if [ -d "/c/Ultibo/Core" ]; then
	LAZDIR=/c/Ultibo/Core
fi

if [ -d "$HOME/ultibo/core" ]; then
	LAZDIR="$HOME/ultibo/core"
fi

LPINAME=fipq
MODES="QEMUVPB RPI RPI2 RPI3"

function buildmode {
    MODE=$1
    echo $MODE
    rm -rf lib/ *.elf kernel*.img kernel.bin
    WD=$(pwd)
    pushd $LAZDIR >& /dev/null
    ./lazbuild --build-mode=BUILD_MODE_$MODE $WD/$LPINAME.lpi
    popd >& /dev/null
}

for MODE in $MODES
do
    buildmode $MODE
done
