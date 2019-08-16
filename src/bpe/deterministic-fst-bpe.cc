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


#include "bpe/deterministic-fst-bpe.h"

namespace kaldi{
namespace fst {
using fst::BPEDeterministicOnDemandFst;
/// \addtogroup deterministic_fst_group "Classes and functions related to on-demand deterministic FST's"
/// @{

/// class DeterministicOnDemandFst is an "FST-like" base-class.  It does not
/// actually inherit from any Fst class because its interface is not exactly the
/// same; it's much smaller.  It assumes that the FST can have only one arc for
/// any given input symbol, which makes the GetArc function below possible.
/// (The FST is also assumed to be free of input epsilons).  Note: we don't use
/// "const" in this interface, because it creates problems when we do things
/// like caching.

BPEDeterministicOnDemandFst::BPEDeterministicOnDemandFst(LexiconMap *lexicon_map, BpeStopSymbols *bpe_stops) {
  lexicon_map_ = lexicon_map;
  bpe_stops_ = bpe_stops;
  start_state_ = 0;
  std::vector<Label> bos;
  bseq_to_state_[bos] = 0;
  state_to_bseq_.push_back(bos);
}

StateId BPEDeterministicOnDemandFst<StdArc>::Start() {
  return start_state_; //equivalent to "return this->start_state_;"
}

Weight BPEDeterministicOnDemandFst<StdArc>::Final(StateId s) {
  // Final 
  typedef MapType::iterator IterType;
  std::vector<Label> bseq = state_to_bseq_[s];
  BaseFloat logprob;
  if (bpe_stops_->find(bseq.back())) {// Last bpe piece is in stop bpe list
    logprob = 1;
  } else {
    logprob = -16.118; // Fixed number ???
  }
  return Weight(-logprob);
}

BPEDeterministicOnDemandFst::~BPEDeterministicOnDemandFst() {
  for (int i = 0; i < state_to_bseq_.size(); i++) {
    delete state_to_bseq_[i];
  }
}

void BPEDeterministicOnDemandFst::Clear() {
  // similar to the destructor but we retain the 0-th entries in each map
  // which corresponds to the <bos> state
  for (int i = 1; i < state_to_bseq_.size(); i++) {
    delete state_to_bseq_[i];
  }
  state_to_bseq_.resize(1);
  bseq_to_state_.clear();
  bseq_to_state_[state_to_bseq_[0]] = 0;
}


bool BPEDeterministicOnDemandFst::GetArc(StateId s, Label ilabel, StdArc *oarc) {
  std::vector<Label> bseq = state_to_bseq_[s].push_back(ilabel);
  std::pair<const std::vector<Label>, StateId> bseq_state_pair(bseq, static_cast<Label>(state_to_bseq_.size()));
  typedef MapType::iterator IterType;
  std::pari<IterType, bool> result = bseq_to_state_.insert(bseq_state_pair);
  // Check if this bseq is already related to a state. If not, push back this new bseq.
  if (result.second == true) {
    state_to_bseq_.push_back(bseq);
  } 

  // Create the oarc
  oarc->ilabel = ilabel
  if (bpe_stops_->find(ilabel)) {
    oarc->olabel = lexicon_map_->find(bseq);
    state_to_bseq_
  } else{
    oarc->olabel = 0;
    oarc->nextstate = result.first->second;
  }
  oarc->weight = Weight::One();
}
} //namespace fst
} //namespace kaldi
