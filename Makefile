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

.PHONY: all
all:
	$(MK) -C "$(srctop)/llvm-project" _build_clang

.PHONY: _build_clang
_build_clang:
	cmake -S "./llvm" -B "./build" $(conf_llvm)
	cmake --build "./build" -j $$(nproc) --target install
