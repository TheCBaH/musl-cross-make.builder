#!/bin/sh
set -eu
#set -x
src=$1
dst=$2
code=$3
base=$(basename $src)
base=${base%.tar}
target=$(echo $base | sed 's/musl-cross-\(.*\)-gcc.*/\1/')
prog=$dst/${code%.c}.$base
dst="$dst/$base"
rm -rf $dst
mkdir -p $dst
echo "Extracting $src"
tar -xf $src -C $dst
echo "Compiling $code"
$dst/bin/$target-cc $code -o $prog
echo "Running $prog"
qemu-$(./tool.sh $dst $target qemu-arch) -L $(./tool.sh $dst $target lib) $prog
