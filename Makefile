all:
	echo 'Not supported' >&2

musl=musl-cross-make
patches.make:
	git -C ${musl} format-patch $$(git ls-tree HEAD ${musl} | awk '{print $$3}')
	mkdir -p $(basename $@)
	mv -v musl-cross-make/00* $(basename $@)/

patches.apply:
	git -C ${musl} checkout .
	git submodule update ${musl}
	set -eux; for p in $(wildcard $(realpath patches)/*); do\
		git -C ${musl} apply --verbose $$p;\
		#git -C ${musl} am $$p;\
	done

empty:=
space+= ${empty} ${empty}
coma=,

CPUS=$(or $(shell getconf _NPROCESSORS_ONLN 2>/dev/null),1)

config,%:
	${MAKE} -C ${musl} clean
	set -eux;\
	 gcc='$(word 2, $(subst ${coma},${space},$@))';\
	 target='$(word 3, $(subst ${coma},${space},$@))';\
	 rm -f ${musl}/config.mak;\
	 cp config.mak.musl ${musl}/config.mak;\
	 echo "GCC_VER=$$gcc" >> ${musl}/config.mak;\
	 echo "TARGET=$$target" >> ${musl}/config.mak;\
	 if [ "$$gcc" = '5.3.0' ] || [ "$$gcc" = '6.5.0' ]; then\
		echo "CFLAGS_WARN=-w" >> ${musl}/config.mak;\
	 fi

CCACHE_CONFIG=--max-size=128M --set-config=compression=true
CCACHE_DIR=${CURDIR}/.ccache
export CCACHE_DIR

ccache-init:
	ccache --version
	ccache ${CCACHE_CONFIG} --show-config

ccache-stat:
	ccache --show-stat

build,%:
	${MAKE} $(subst build${coma},config${coma},$@)
	${MAKE} -C ${musl} -j${CPUS} CCACHE=ccache

OUTDIR=out

install,%:
	set -eux;\
	 target='$(word 3, $(subst ${coma},${space},$@))';\
	 gcc='$(word 2, $(subst ${coma},${space},$@))';\
	 dst=${OUTDIR}/$$gcc/$$target;\
	 rm -rf $$dst;\
	 ${MAKE} -C ${musl} TARGET=$$target OUTPUT="$$(readlink -m $$dst)" install;\
	 $$dst/bin/$$target-cc -v;\
	 ./tool.sh $$dst $$target fixup

test,%:
	set -eux;\
	 target='$(word 3, $(subst ${coma},${space},$@))';\
	 gcc='$(word 2, $(subst ${coma},${space},$@))';\
	 dst=${OUTDIR}/$$gcc/$$target;\
	 bin=${OUTDIR}/$${gcc}_$${target}_test;\
	 $$dst/bin/$$target-cc hello.c -o $$bin;\
	 qemu-$$(./tool.sh $$dst $$target qemu-arch) -L $$(./tool.sh $$dst $$target lib) $$bin

clean:
	${MAKE} -C ${musl} $@
	rm -rf out

devcontainer:
	npm install -g @devcontainers/cli
	devcontainer build --workspace-folder .
	devcontainer up --workspace-folder .
	devcontainer exec --workspace-folder . ccache --version
	devcontainer exec --workspace-folder . qemu-i386 --version
