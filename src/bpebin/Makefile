
all:


EXTRA_CXXFLAGS = -Wno-sign-compare

include ../kaldi.mk
OBJFILES =
TESTFILES = 
BINFILES = lattice-bpe-to-word

ADDLIBS = ../lat/kaldi-lat.a ../bpe/kaldi-bpe.a ../fstext/kaldi-fstext.a \
          ../util/kaldi-util.a ../base/kaldi-base.a

include ../makefiles/default_rules.mk
