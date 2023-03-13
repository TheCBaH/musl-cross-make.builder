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
case "$arch" in
powerpc*)
    qemu_arch="ppc${arch#powerpc}"
    ;;
*)
    qemu_arch="$arch"
    ;;
esac
ld=ld-musl-${arch}${kind}.so.1

case "$cmd" in
fixup)
    link=$(readlink $lib/$ld)
    link=$(basename $link)
    rm -rf $lib/$ld
    ln -s $link $lib/$ld
    ;;
qemu-arch)
    echo $qemu_arch
    ;;
lib)
    echo $lib_root
    ;;
meta)
    grep '^GCC_VER\|^TARGET' musl-cross-make/config.mak >$dst/bin/.$target
    grep '^BINUTILS_VER\|^MUSL_VER\|^GMP_VER\|^MPC_VER\|^MPFR_REV\|^LINUX_VER' musl-cross-make/Makefile >>$dst/bin/.$target
    cat <<_EOF_ >$dst/bin/$target
#!/bin/sh
set -eu
#set -x
this=\$(dirname \$0)/..
_EOF_
if [ $arch = x86_64 ] || [ $arch = i386 ]; then
    echo "exec \$this/$target/lib/$ld \"\$@\"" >>$dst/bin/$target
else
    echo "exec qemu-$qemu_arch -L \$this/$target \"\$@\"" >>$dst/bin/$target
fi
    chmod +x $dst/bin/$target
    ;;
*)
    echo "Not supported '$cmd'" >&2
    exit 1
    ;;
esac
