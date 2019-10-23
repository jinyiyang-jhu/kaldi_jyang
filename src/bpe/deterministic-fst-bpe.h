// bpe/deterministic-fst-bpe.h

// Copyright 2019 Johns Hopkins University (author: Jinyi Yang)


#ifndef KALDI_FSTEXT_DETERMINISTIC_FST_BPE_H_
#define KALDI_FSTEXT_DETERMINISTIC_FST_BPE_H_

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include <fst/fstlib.h>
#include <fst/fst-decl.h>
#include "util/stl-utils.h"
#include "fstext/deterministic-fst.h"

namespace fst {
class BPEDeterministicOnDemandFst: public DeterministicOnDemandFst<StdArc> {
  private:
    typedef typename StdArc::Weight Weight;
    typedef typename StdArc::StateId StateId;
    typedef typename StdArc::Label Label;
    typedef std::unordered_map<std::vector<Label>, StateId, kaldi::VectorHasher<Label> > MapType;
    typedef std::unordered_map<std::vector<Label>, Label, kaldi::VectorHasher<Label> > LexiconMap;
    typedef std::unordered_set<Label> BpeStopSymbols;

    LexiconMap *lexicon_map_;    // Mapping from BPE sequences to word
    BpeStopSymbols *bpe_stops_; // Set of bpe symbols which can be ending unit
    StateId start_state_;  // Fst start state
    MapType bseq_to_state_;   // Mapping from BPE sequence to fst state id
    std::vector<std::vector<Label> > state_to_context_; // Store the BPE context of each state
    Label unk_int_; // Label for the OOV word

  public:
    BPEDeterministicOnDemandFst(LexiconMap *lexicon_map, BpeStopSymbols*bpe_stops, Label unk_int);
    ~BPEDeterministicOnDemandFst();
    void Clear();
    virtual StateId Start();
    virtual Weight Final(StateId s);
    virtual bool GetArc(StateId s, Label ilabel, StdArc *oarc);
};
} // namespace fst
#endif
