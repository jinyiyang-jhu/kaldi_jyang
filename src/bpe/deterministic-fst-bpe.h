// fstext/deterministic-fst-bpe.h

// Copyright 2019 Johns Hopkins University (author: Jinyi Yang)

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

#ifndef KALDI_FSTEXT_DETERMINISTIC_FST_BPE_H_
#define KALDI_FSTEXT_DETERMINISTIC_FST_BPE_H_

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

    LexiconMap *lexicon_map_;    // Unordered map from vector of bpe symbols (ints) to corresponding word (int)
    BpeStopSymbols *bpe_stops_; // Unordered map storing bpe symbols (ints) that can end words (without @@ at the end)
    StateId start_state_;  // Fst start/end state

    // Panda suspicious code...
    MapType bseq_to_state_;   // Stores BPE sequence to state map
    std::vector<std::vector<Label> > state_to_bseq_; // Store the BPE sequence symbol corresponding to an FST state
    Label unk_int_;
        //int max_len_; // Place to store the max length of input bpe sequence, if it
                    //is beyond this length without matching word, clear the context and output oov-symbol;
  public:
    //It takes in the word-to-bpe vocabulary, and stop words list.
    BPEDeterministicOnDemandFst(LexiconMap *lexicon_map, BpeStopSymbols*bpe_stops, Label unk_int);
    virtual ~BPEDeterministicOnDemandFst() {};
    void Clear();
    virtual StateId Start();
    virtual Weight Final(StateId s);
    virtual bool GetArc(StateId s, Label ilabel, StdArc *oarc);
};
} // namespace fst
#endif
