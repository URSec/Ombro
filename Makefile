srctop := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
builddist := $(srctop)/builddist
dist := $(srctop)/dist

.PHONY: all
all:
