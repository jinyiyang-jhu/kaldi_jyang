// fstext/deterministic-fst-bpe.h

// Copyright 2011-2012 Gilles Boulianne
//                2014 Telepoint Global Hosting Service, LLC. (Author: David Snyder)
//           2012-2015 Johns Hopkins University (author: Daniel Povey)

// See ../../COPYING for clarification regarding multiple authors
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
// See ../../COPYING for clarification regarding multiple authors
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
//
// Copyright 2005-2010 Google, Inc.
// Author: riley@google.com (Michael Riley)

#ifndef KALDI_FSTEXT_DETERMINISTIC_FST_H_
#define KALDI_FSTEXT_DETERMINISTIC_FST_H_

/* This header defines the DeterministicOnDemand interface,
   which is an FST with a special interface that allows
   only a single arc with a non-epsilon input symbol
   out of each state.
*/

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include <fst/fstlib.h>
#include <fst/fst-decl.h>

#include "util/stl-utils.h"
#include "hmm/transition-model.h"
#include "fstext/deterministic-fst.h"

namespace kaldi{
namespace fst {

/// \addtogroup deterministic_fst_group "Classes and functions related to on-demand deterministic FST's"
/// @{

/// class DeterministicOnDemandFst is an "FST-like" base-class.  It does not
/// actually inherit from any Fst class because its interface is not exactly the
/// same; it's much smaller.  It assumes that the FST can have only one arc for
/// any given input symbol, which makes the GetArc function below possible.
/// (The FST is also assumed to be free of input epsilons).  Note: we don't use
/// "const" in this interface, because it creates problems when we do things
/// like caching.


template<class Arc>
class BPEDeterministicOnDemandFst:
        public fst::DeterministicOnDemandFst<fst::StdArc> {
 public:
  typedef fst::StdArc::StateId StateId;
  typedef fst::StdArc::Weight Weight;
  typedef fst::StdArc::Label Label;

  //It takes in the word-to-bpe vocabulary, and stop words list.
  BPEDeterministicOnDemandFst(LexiconMap *lexicon, StopWords *stop_words);
  virtual StateId Start() { return start_state_; }
  virtual Weight Final(StateId s);
  virtual bool GetArc(StateId s, Label ilabel, fst::StdArc *oarc);

 private:
  typedef std::unordered_map<std::vector<Label>, StateId, VectorHasher<Label> > MapType;
  typedef std::unordered_map<std::vector<Label>, Label, VectorHasher<Label> > LexiconMap;
  typedef std::unordered_set<Label> BpeStopSymbols;

  MapType bseq_to_state_;   // Stores BPE sequence to state map
  LexiconMap *lexicon_map_;    // Unordered map from vector of bpe symbols (ints) to corresponding word (int)
  BpeStopSymbols *bpe_stops_; // Unordered map storing bpe symbols (ints) that can end words (without @@ at the end)
  StateId start_state_ = 0; // Fst start state
  //int max_len_; // Place to store the max length of input bpe sequence, if it
                //is beyond this length without matching word, clear the context and output oov-symbol;

  // Map from history-state to pair.
  std::vector<std::vector<Label> > state_to_bseq_; // Store the BPE sequence symbol corresponding to an FST state
};
} //namespace fst
} //namespace kaldi
