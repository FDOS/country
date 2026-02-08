# Makefile for DOS NASM Framework
# Build with: gmake
# Build NLS library: make nls
# Build all NLS variants: make nls_all
# Clean with: make clean

#============================================================================
# Tools Configuration
#============================================================================
#WATCOM = /opt/watcom
#WCC = $(WATCOM)/binl64/wcc
#WLINK = $(WATCOM)/binl64/wlink
WCC = wcc
WLINK = wlink
NASM = nasm

# Watcom environment
#export WATCOM
#export PATH := $(WATCOM)/binl64:$(WATCOM)/binl:$(PATH)
#export INCLUDE := $(WATCOM)/h

#============================================================================
# Compiler Identifiers (for object file naming)
# wat = Watcom, bcc = Borland, gcc = GCC-ia16, msc = Microsoft, dmc = Digital Mars
#============================================================================
COMPILERS = wat bcc gcc msc dmc

#============================================================================
# Memory Model Identifiers
# t = tiny, s = small, c = compact, m = medium, l = large
#============================================================================
MODELS = t s c m l

#============================================================================
# Model Configuration Mappings
#============================================================================
# NASM MODEL names
MODEL_t = TINY
MODEL_s = SMALL
MODEL_c = COMPACT
MODEL_m = MEDIUM
MODEL_l = LARGE

# Watcom memory model flags
WCC_MODEL_t = -mt
WCC_MODEL_s = -ms
WCC_MODEL_c = -mc
WCC_MODEL_m = -mm
WCC_MODEL_l = -ml

# NASM COMPILER names
COMPILER_wat = WATCOM
COMPILER_bcc = BORLAND
COMPILER_gcc = GCC
COMPILER_msc = MSC
COMPILER_dmc = DMC

#============================================================================
# Default Build Configuration
#============================================================================
MODEL = SMALL
WCC_MODEL = -ms
COMPILER = WATCOM

# Compiler flags
# -ecc = use cdecl calling convention (adds underscore prefix)
# -zq = quiet mode
# -0 = 8086 code
WCC_FLAGS = $(WCC_MODEL) -ecc -zq -0

# NASM flags
NASM_FLAGS = -f obj -DMODEL=$(MODEL) -DCOMPILER=$(COMPILER)

#============================================================================
# Output Files
#============================================================================
TARGET = test.exe
NLS_TARGET = nlstest.exe
NLSDUMP_TARGET = nlsdump.exe

# Object files
OBJS = test.obj sample.obj
NLS_OBJS = nlstest.obj nls.obj
NLSDUMP_OBJS = nlsdump.obj nls.obj

#============================================================================
# Standard Targets
#============================================================================
.PHONY: all clean nls nls_all test nlstest nlsdump

all: $(TARGET)

# Link the sample test executable
$(TARGET): $(OBJS)
	$(WLINK) system dos file test.obj,sample.obj name $(TARGET)

# Compile C source
test.obj: test.c
	$(WCC) $(WCC_FLAGS) test.c -fo=test.obj

# Assemble ASM source
sample.obj: sample.asm dosazm.inc
	$(NASM) $(NASM_FLAGS) sample.asm -o sample.obj

#============================================================================
# NLS Library Targets
#============================================================================

# Build NLS test with default (Watcom small model)
nls: $(NLS_TARGET)

$(NLS_TARGET): $(NLS_OBJS)
	$(WLINK) system dos file nlstest.obj,nls.obj name $(NLS_TARGET)

nlstest.obj: nlstest.c nls.h
	$(WCC) $(WCC_FLAGS) nlstest.c -fo=nlstest.obj

nls.obj: nls.asm dosazm.inc
	$(NASM) $(NASM_FLAGS) nls.asm -o nls.obj

#============================================================================
# NLS Dump Utility Target
#============================================================================

nlsdump: $(NLSDUMP_TARGET)

$(NLSDUMP_TARGET): $(NLSDUMP_OBJS)
	$(WLINK) system dos file nlsdump.obj,nls.obj name $(NLSDUMP_TARGET)

nlsdump.obj: nlsdump.c nls.h
	$(WCC) $(WCC_FLAGS) nlsdump.c -fo=nlsdump.obj

#============================================================================
# NLS Library Multi-Compiler/Model Build
#============================================================================
# Generate all nls_CCCM.obj variants
# Example: nls_wats.obj (Watcom small), nls_bccm.obj (Borland medium)

# List of all NLS object files
NLS_ALL_OBJS = $(foreach cc,$(COMPILERS),$(foreach mm,$(MODELS),nls_$(cc)$(mm).obj))

nls_all: $(NLS_ALL_OBJS)
	@echo "Built all NLS library variants:"
	@ls -la nls_*.obj 2>/dev/null || echo "  (none found)"

# Rule to build nls_CCCM.obj files
# Pattern: nls_$(CC)$(M).obj where CC is compiler and M is model
# We use a helper script approach since Make pattern rules are limited

# Watcom variants
nls_watt.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=TINY -DCOMPILER=WATCOM nls.asm -o $@

nls_wats.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=SMALL -DCOMPILER=WATCOM nls.asm -o $@

nls_watc.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=COMPACT -DCOMPILER=WATCOM nls.asm -o $@

nls_watm.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=MEDIUM -DCOMPILER=WATCOM nls.asm -o $@

nls_watl.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=LARGE -DCOMPILER=WATCOM nls.asm -o $@

# Borland variants
nls_bcct.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=TINY -DCOMPILER=BCC nls.asm -o $@

nls_bccs.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=SMALL -DCOMPILER=BCC nls.asm -o $@

nls_bccc.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=COMPACT -DCOMPILER=BCC nls.asm -o $@

nls_bccm.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=MEDIUM -DCOMPILER=BCC nls.asm -o $@

nls_bccl.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=LARGE -DCOMPILER=BCC nls.asm -o $@

# GCC-ia16 variants
nls_gcct.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=TINY -DCOMPILER=GCC nls.asm -o $@

nls_gccs.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=SMALL -DCOMPILER=GCC nls.asm -o $@

nls_gccc.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=COMPACT -DCOMPILER=GCC nls.asm -o $@

nls_gccm.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=MEDIUM -DCOMPILER=GCC nls.asm -o $@

nls_gccl.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=LARGE -DCOMPILER=GCC nls.asm -o $@

# Microsoft C variants
nls_msct.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=TINY -DCOMPILER=MSC nls.asm -o $@

nls_mscs.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=SMALL -DCOMPILER=MSC nls.asm -o $@

nls_mscc.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=COMPACT -DCOMPILER=MSC nls.asm -o $@

nls_mscm.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=MEDIUM -DCOMPILER=MSC nls.asm -o $@

nls_mscl.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=LARGE -DCOMPILER=MSC nls.asm -o $@

# Digital Mars variants
nls_dmct.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=TINY -DCOMPILER=DMC nls.asm -o $@

nls_dmcs.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=SMALL -DCOMPILER=DMC nls.asm -o $@

nls_dmcc.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=COMPACT -DCOMPILER=DMC nls.asm -o $@

nls_dmcm.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=MEDIUM -DCOMPILER=DMC nls.asm -o $@

nls_dmcl.obj: nls.asm dosazm.inc
	$(NASM) -f obj -DMODEL=LARGE -DCOMPILER=DMC nls.asm -o $@

#============================================================================
# Memory Model Convenience Targets
#============================================================================

# Build test.exe with specific model
small: MODEL=SMALL
small: WCC_MODEL=-ms
small: clean all

medium: MODEL=MEDIUM
medium: WCC_MODEL=-mm
medium: clean all

compact: MODEL=COMPACT
compact: WCC_MODEL=-mc
compact: clean all

large: MODEL=LARGE
large: WCC_MODEL=-ml
large: clean all

# Build nlstest.exe with specific model
nls_small: MODEL=SMALL
nls_small: WCC_MODEL=-ms
nls_small: clean nls

nls_medium: MODEL=MEDIUM
nls_medium: WCC_MODEL=-mm
nls_medium: clean nls

nls_compact: MODEL=COMPACT
nls_compact: WCC_MODEL=-mc
nls_compact: clean nls

nls_large: MODEL=LARGE
nls_large: WCC_MODEL=-ml
nls_large: clean nls

#============================================================================
# Clean Target
#============================================================================
clean:
	rm -f *.obj *.exe *.err *.map

#============================================================================
# Help Target
#============================================================================
help:
	@echo "DOS NASM Framework Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build sample test.exe (default: Watcom small)"
	@echo "  nls          - Build NLS test nlstest.exe (Watcom small)"
	@echo "  nlsdump      - Build NLS dump utility nlsdump.exe"
	@echo "  nls_all      - Build all NLS library variants (nls_CCCM.obj)"
	@echo "  small/medium/compact/large - Build test.exe with specific model"
	@echo "  nls_small/nls_medium/...   - Build nlstest.exe with specific model"
	@echo "  clean        - Remove all generated files"
	@echo "  help         - Show this help"
	@echo ""
	@echo "NLS Library Variants (nls_all target):"
	@echo "  Compilers: wat (Watcom), bcc (Borland), gcc (GCC-ia16),"
	@echo "             msc (Microsoft), dmc (Digital Mars)"
	@echo "  Models:    t (tiny), s (small), c (compact), m (medium), l (large)"
	@echo "  Example:   nls_wats.obj = Watcom small model"
	@echo ""
