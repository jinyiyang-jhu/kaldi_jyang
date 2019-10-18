// fstext/deterministic-fst-bpe.cc

// Copyright 2019 Johns Hopkins University (author: Jinyi Yang)


//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.
//
// This file includes material from the OpenFST Library v1.2.7 available at
// http://www.openfst.org and released under the Apache License Version 2.0.
//

//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
  // Return the start state
  return start_state_; //equivalent to "return this->start_state_;"
}

StdArc::Weight BPEDeterministicOnDemandFst::Final(StateId s) {
  // Find the weight for the current state. If it is a final state, the weight
  // is log-probablity is 0; otherwise, the log-probability is negative
  // infinity.
  // The way to decide whether a state is final, is to find if the related
  // ilabel to the state is in the stop symbol list. If yes then it is a final
  // state; otherwise it is not a final state (suppose no lattice ends with a
  // non-stop bpe piece).
  typedef MapType::iterator IterType;
  std::vector<Label> bseq = state_to_context_[s];
  kaldi::BaseFloat logprob;
  KALDI_WARN << "State "<< s << " context is ";
  BPEDeterministicOnDemandFst::PrintVec(state_to_context_[s]);
  if (state_to_context_[s].size() == 0) { // Is final state
    //logprob = 0;
    return Weight::One();
  //if (bpe_stops_->find(state_to_context_[s]) != bpe_stops_->end()) {
    // The current context is in stop symbol list
  } else {
    //logprob =  -numeric_limits<kaldi::BaseFloat>::infinity();
    return Weight::Zero();
  }
  //return Weight(-logprob);
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
  // Create the lexicon fst on demand.
  std::vector<Label> bseq = state_to_context_[s]; // This is the context related to the current state.
  KALDI_WARN << "Current bseq is ";
  BPEDeterministicOnDemandFst::PrintVec(bseq);
  std::pair<const std::vector<Label>, StateId> bseq_state_pair(bseq, static_cast<Label>(state_to_context_.size()));
  typedef MapType::iterator IterType;
  std::pair<IterType, bool> result = bseq_to_state_.insert(bseq_state_pair);
  // Check if this bseq is already related to a state. If not, push back this new bseq.
  if (result.second == true) {
    KALDI_WARN << "Inserting new bseq to state " << s;
    state_to_context_.push_back(bseq);
  }
  // Create the oarc
  oarc->ilabel = ilabel;
  oarc->nextstate = result.first->second;
  KALDI_WARN << "Pair is bseq and " << state_to_context_.size() << "==" << result.first->second;
  //KALDI_WARN << "Next state is " << oarc->nextstate;
  state_to_context_[oarc->nextstate] = state_to_context_[s];
  state_to_context_[oarc->nextstate].push_back(ilabel);
  KALDI_WARN << "Print current context";
  BPEDeterministicOnDemandFst::PrintVec(state_to_context_[oarc->nextstate]);
  if (bpe_stops_->find(ilabel) != bpe_stops_->end()) {
    KALDI_WARN << "*** Found an stop int: " << ilabel;
    KALDI_WARN << "context length is " << state_to_context_[s].size();
    //KALDI_WARN << "Print context of state " << s;
    //BPEDeterministicOnDemandFst::PrintVec(state_to_context_[oarc->nextstate]);
    LexiconMap::iterator it = lexicon_map_->find(state_to_context_[oarc->nextstate]);
    if (it != lexicon_map_->end()){
      oarc->olabel = it->second;
    } else{
      oarc->olabel = unk_int_;
    }
    state_to_context_[oarc->nextstate].clear();
  } else{
    oarc->olabel = 0;
  }
  oarc->weight = Weight::One();
  return true;

}
} //namespace fst

