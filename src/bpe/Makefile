
# make "all" the target.
all:

# Disable linking math libs because  not needed here.  Just for compilation speed.
# no, it's now needed for context-fst-test.
# MATHLIB = NONE

EXTRA_CXXFLAGS = -Wno-sign-compare

include ../kaldi.mk
OBJFILES =  deterministic-fst-bpe.o
BINFILES = build-bpe-on-demand-fst

LIBNAME = kaldi-bpe

# tree and matrix archives needed for test-context-fst
# matrix archive needed for push-special.
ADDLIBS = ../tree/kaldi-tree.a ../util/kaldi-util.a ../matrix/kaldi-matrix.a \
          ../base/kaldi-base.a ../lat/kaldi-lat.a ../fstext/kaldi-fstext.a

include ../makefiles/default_rules.mk
