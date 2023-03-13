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

case "$cmd" in
fixup)
    ld=ld-musl-${arch}${kind}.so.1
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
    grep '^GCC_VER' musl-cross-make/config.mak >$dst/.config
    grep '^BINUTILS_VER\|^MUSL_VER\|^GMP_VER\|^MPC_VER\|^MPFR_REV\|^LINUX_VER' musl-cross-make/Makefile >>$dst.config
    cat <<_EOF_ >$dst/with-target
#!/bin/sh
set -eu
exec qemu-$qemu_arch -L $lib_root \$@
_EOF_
    chmod +x $dst/with-target
    ;;
*)
    echo "Not supported '$cmd'" >&2
    exit 1
    ;;
esac
