//  bpe/deterministic-fst-bpe.cc

//  2019 Johns Hopkins University (author: Jinyi Yang)

#include "base/kaldi-common.h"
#include "bpe/deterministic-fst-bpe.h"

namespace fst {

BPEDeterministicOnDemandFst::BPEDeterministicOnDemandFst(LexiconMap *lexicon_map, BpeStopSymbols *bpe_stops, Label unk_int) {
  lexicon_map_ = lexicon_map;
  bpe_stops_ = bpe_stops;
  unk_int_ = unk_int;
  start_state_ = 0;
  std::vector<Label> bos;
  bseq_to_state_[bos] = 0;
  state_to_context_.push_back(bos);
}

StdArc::StateId BPEDeterministicOnDemandFst::Start() {
  return start_state_; 
}

StdArc::Weight BPEDeterministicOnDemandFst::Final(StateId s) {
  // Compute the final weight for the current state.
  // If the context of current state is empty, it means that we have found a
  // stop symbol in the previous GetArc() function, then this state should be
  // final.
  if (state_to_context_[s].size() == 0) { // It is final state.
    return Weight::One();
  } else {
    return Weight::Zero();
  }
}

BPEDeterministicOnDemandFst::~BPEDeterministicOnDemandFst() {
  state_to_context_.clear();
}

void BPEDeterministicOnDemandFst::Clear() {
  state_to_context_.resize(1);
  bseq_to_state_.clear();
  bseq_to_state_[state_to_context_[0]] = 0;
}

bool BPEDeterministicOnDemandFst::GetArc(StateId s, Label ilabel, StdArc *oarc) {
  // Create the lexicon fst.
  std::vector<Label> bseq = state_to_context_[s]; // This is the context related to the current state.
  bseq.push_back(ilabel);
  std::pair<const std::vector<Label>, StateId> bseq_state_pair(bseq, static_cast<Label>(state_to_context_.size()));
  typedef MapType::iterator IterType;
  std::pair<IterType, bool> result = bseq_to_state_.insert(bseq_state_pair);

  // Check whether this bseq is already related to a state. If not, push back this new bseq.
  if (result.second == true) {
    state_to_context_.push_back(bseq);
  }
  // Create the oarc
  oarc->ilabel = ilabel;
  oarc->nextstate = result.first->second;
  state_to_context_[oarc->nextstate] = state_to_context_[s];
  state_to_context_[oarc->nextstate].push_back(ilabel);

  if (bpe_stops_->find(ilabel) != bpe_stops_->end()) {
    // If ilabel is a bpe symbol, the olabel of current arc should be either a
    // word or a "OOV" symbol; and the context of nextstate will be cleared,
    // and nextstate will be a final state.
    LexiconMap::iterator it = lexicon_map_->find(state_to_context_[oarc->nextstate]);
    if (it != lexicon_map_->end()){
      // Found the current context in lexicon, return matching word.
      oarc->olabel = it->second;
    } else{
      // Context not in lexicon, return "OOV" symbol.
      oarc->olabel = unk_int_;
    }
    state_to_context_[oarc->nextstate].clear();
  } else{
    // The current ilabel is not in the stop symbol list.
    oarc->olabel = 0;
  }
  oarc->weight = Weight::One(); // We don't want to change the weight of the
  // composed lattice, so the lexicon fst weight is set zero.
  return true;

}
} //namespace fst

