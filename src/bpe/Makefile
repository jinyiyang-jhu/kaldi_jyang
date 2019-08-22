
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
ADDLIBS = ../fstext/kaldi-fstext.a ../util/kaldi-util.a \
          ../base/kaldi-base.a ../lat/kaldi-lat.a

include ../makefiles/default_rules.mk
