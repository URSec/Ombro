start_time := $(shell date +%s)
srctop := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
builddist := $(srctop)/builddist
dist := $(srctop)/dist

MK = $(MAKE) -f "$(srctop)/Makefile"

conf_llvm :=	-DCMAKE_INSTALL_PREFIX="$(builddist)"	\
		-DCMAKE_BUILD_TYPE='Release'		\
		-DLLVM_TARGETS_TO_BUILD='X86'		\
		-DLLVM_ENABLE_PROJECTS='clang;lld'	\
		-DLLVM_ENABLE_BINDINGS='false'		\
		-DLLVM_ENABLE_ASSERTIONS='true'		\

conf_sva :=	--prefix="$(builddist)"		\
		--with-hacks-for='xen'		\
		--enable-split-stack		\

conf_xen :=	--prefix="$(dist)"		\
		--disable-tools			\
		--disable-docs			\
		--disable-stubdom		\

.PHONY: all
all:
	$(MK) -C "$(srctop)/llvm-project" _build_clang
	$(MK) -C "$(srctop)/SVA" _build_sva
	$(MK) -C "$(srctop)/Xen" _build_xen
	@printf "\n\e[32mBuild completed successfully in %ds\e[0m\n" "$$(($$(date +%s) - $(start_time)))"

.PHONY: _build_clang
_build_clang:
	cmake -S "./llvm" -B "./build" $(conf_llvm)
	cmake --build "./build" -j $$(nproc) --target install

# Use our newly built compiler to build the following targets
uses_sva_compiler := _build_sva _build_xen
$(uses_sva_compiler): export PATH:=$(builddist)/bin:$(PATH)
$(uses_sva_compiler): export LD_LIBRARY_PATH:=$(builddist)/lib:$(LD_LIBRARY_PATH)
$(uses_sva_compiler): export C_INCLUDE_PATH:=$(builddist)/include:$(C_INCLUDE_PATH)
$(uses_sva_compiler): export CPLUS_INCLUDE_PATH:=$(builddist)/include:$(CPLUS_INCLUDE_PATH)

.PHONY: _build_sva
_build_sva:
	autoconf -o configure autoconf/configure.ac
	./configure $(conf_sva)
	$(MAKE) -j -C SVA install

.PHONY: _build_xen
_build_xen:
	sed 's@$$builddist@$(builddist)@g' < "$(srctop)/xenbuild.config" > .config
	./configure $(conf_xen)
	cp -p "xen/sva.config" "xen/.config"
	$(MAKE) -j DESTDIR="$(dist)" install
