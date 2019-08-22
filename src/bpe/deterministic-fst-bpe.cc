#include "base/kaldi-common.h"
#include "bpe/deterministic-fst-bpe.h"

namespace fst {
//using fst::BPEDeterministicOnDemandFst;

BPEDeterministicOnDemandFst::BPEDeterministicOnDemandFst(LexiconMap *lexicon_map, BpeStopSymbols *bpe_stops, Label unk_int) {
  lexicon_map_ = lexicon_map;
  bpe_stops_ = bpe_stops;
  unk_int_ = unk_int;
  start_state_ = 0;
  std::vector<Label> bos;
 // bseq_to_state_[bos] = 0;
  state_to_context_.push_back(bos);
}

StdArc::StateId BPEDeterministicOnDemandFst::Start() {
  return start_state_; //equivalent to "return this->start_state_;"
}

StdArc::Weight BPEDeterministicOnDemandFst::Final(StateId s) {
  // Final 
  typedef MapType::iterator IterType;
  KALDI_LOG << "BPE final state";
  std::vector<Label> bseq = state_to_context_[s];
  KALDI_LOG << "Bseq size is " << bseq.size();
  kaldi::BaseFloat logprob;
  if (bpe_stops_->find(bseq.back()) != bpe_stops_->end()) {// Last bpe piece is in stop bpe list
    logprob = 0;
    state_to_context_[s].clear();
  } else {
    logprob =  - numeric_limits<kaldi::BaseFloat>::infinity();
  }
  return Weight(-logprob);
}

//BPEDeterministicOnDemandFst::~BPEDeterministicOnDemandFst() {
  //for (int i = 0; i < state_to_context_.size(); i++) {
  //  delete state_to_context_[i];
//  }
//}

void BPEDeterministicOnDemandFst::Clear() {
  // similar to the destructor but we retain the 0-th entries in each map
  // which corresponds to the <bos> state
  state_to_context_.resize(1);
  bseq_to_state_.clear();
  bseq_to_state_[state_to_context_[0]] = 0;
}

bool BPEDeterministicOnDemandFst::GetArc(StateId s, Label ilabel, StdArc *oarc) {
  KALDI_LOG << ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>";
  //KALDI_LOG << "GetArc: (StateId, Inlabel) = (" << s << ",  " <<ilabel << ")";
  std::vector<Label> bseq = state_to_context_[s];
  std::pair<const std::vector<Label>, StateId> bseq_state_pair(bseq, static_cast<Label>(state_to_context_.size()));
  typedef MapType::iterator IterType;
  std::pair<IterType, bool> result = bseq_to_state_.insert(bseq_state_pair);
  // Check if this bseq is already related to a state. If not, push back this new bseq.
  if (result.second == true) {
    state_to_context_.push_back(bseq);
  }
  //for (int j =0; j < state_to_context_.size(); ++j) {
    //KALDI_LOG << "Before: state_to_context_: s= " << s <<" , " << j << " th element";
 //   for (int i = 0; i < state_to_context_[j].size(); ++i) {
 //     KALDI_LOG << "Bseq [" << i << "] is " << state_to_context_[j][i];
 //   }
 // }
  // Create the oarc
  oarc->ilabel = ilabel;
  oarc->nextstate = result.first->second;
  state_to_context_[oarc->nextstate] = state_to_context_[s];
  state_to_context_[oarc->nextstate].push_back(ilabel);

  if (bpe_stops_->find(ilabel) != bpe_stops_->end()) {
    LexiconMap::iterator it = lexicon_map_->find(state_to_context_[oarc->nextstate]);
    if (it != lexicon_map_->end()){
      oarc->olabel = it->second;
    } else{
      oarc->olabel = unk_int_;
    }
    //state_to_context_[oarc->nextstate].clear();
  } else{
    oarc->olabel = 0;
  }
  //for (int j =0; j < state_to_context_.size(); ++j) {
  //  KALDI_LOG << "After state_to_context_: s= " << s <<" , " << j << " th element";
  //  for (int i = 0; i < state_to_context_[j].size(); ++i) {
  //    KALDI_LOG << "Bseq [" << i << "] is " << state_to_context_[j][i];
  //  }
  //}
  KALDI_LOG << "State_to_context size is " << state_to_context_.size();
  oarc->weight = Weight::One();
  KALDI_LOG << "Oarc nextstate / label : " << oarc->nextstate << " / " << oarc->olabel;
  return true;
}
} //namespace fst
