#!/bin/sh
set -eu
#set -x
dst=$1
target=$2
cmd=$3

arch=$(echo $target|cut -d- -f 1)
kind=$(echo $target|sed -e 's/.*musl\(eabi\)\{0,1\}//')
lib_root=$dst/$target
lib=$dst/$target/lib
case "$cmd" in
fixup)
    ld=ld-musl-${arch}${kind}.so.1
    link=$(readlink $lib/$ld)
    link=$(basename $link)
    rm -rf $lib/$ld
    ln -s $link $lib/$ld
    ;;
qemu-arch)
    case "$arch" in
    powerpc*)
        arch="ppc${arch#powerpc}"
        ;;
    esac
    echo $arch
    ;;
lib)
    echo $lib_root
    ;;
*)
    echo "Not supported '$cmd'" >&2
    exit 1
    ;;
esac
