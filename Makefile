# This file is a part of Julia. License is MIT: https://julialang.org/license

# This Makefile template requires the following variables to be set
# in the environment or on the command-line:
#   JULIA: path to julia[.exe] executable
#   BIN:   binary build directory

JULIA=~/julia-1.4.2/bin/julia
BIN=.

ifndef JULIA
  $(error "Please pass JULIA=[path of target julia binary], or set as environment variable!")
endif
BIN = .
ifndef BIN
  $(error "Please pass BIN=[path of build directory], or set as environment variable!")
endif

#=============================================================================
# this source directory where embedding.c is located
SRCDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# get the executable suffix, if any
EXE := $(suffix $(abspath $(JULIA)))

# get compiler and linker flags. (see: `contrib/julia-config.jl`)
JULIA_CONFIG := $(JULIA) -e 'include(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia", "julia-config.jl"))' --
CPPFLAGS_ADD :=
CFLAGS_ADD = $(shell $(JULIA_CONFIG) --cflags)
$(info $(CFLAGS_ADD))
LDFLAGS_ADD = -lm $(shell $(JULIA_CONFIG) --ldflags --ldlibs)
$(info $(LDFLAGS_ADD))

DEBUGFLAGS += -g

#=============================================================================

release: $(BIN)/embedding$(EXE)
debug:   $(BIN)/embedding-debug$(EXE)

nim:
	nim c -r -d:JULIA_ENABLE_THREADING=1 --passC:-fPIC --passC:-I/home/rcaillaud/julia-1.4.2/include/julia --clibdir:/home/rcaillaud/julia-1.4.2/lib --passL:-Wl,--export-dynamic --passL:-lm --passL:-Wl,-rpath,/home/rcaillaud/julia-1.4.2/lib/ --passL:-Wl,-rpath,/home/rcaillaud/julia-1.4.2/lib/julia --passL:-ljulia embedding.nim


$(BIN)/embedding$(EXE): $(SRCDIR)/embedding.c
	$(CC) $^ -o $@ $(CPPFLAGS_ADD) $(CPPFLAGS) $(CFLAGS_ADD) $(CFLAGS) $(LDFLAGS_ADD) $(LDFLAGS)

$(BIN)/embedding-debug$(EXE): $(SRCDIR)/embedding.c
	$(CC) $^ -o $@ $(CPPFLAGS_ADD) $(CPPFLAGS) $(CFLAGS_ADD) $(CFLAGS) $(LDFLAGS_ADD) $(LDFLAGS) $(DEBUGFLAGS)

ifneq ($(abspath $(BIN)),$(abspath $(SRCDIR)))
# for demonstration purposes, our demo code is also installed
# in $BIN, although this would likely not be typical
$(BIN)/LocalModule.jl: $(SRCDIR)/LocalModule.jl
	cp $< $@
endif

check: $(BIN)/embedding$(EXE) $(BIN)/LocalModule.jl
	$(JULIA) --depwarn=error $(SRCDIR)/embedding-test.jl $<
	@echo SUCCESS

clean:
	-rm -f $(BIN)/embedding-debug$(EXE) $(BIN)/embedding$(EXE)

.PHONY: release debug clean check

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
print-%:
	@echo '$*=$($*)'
