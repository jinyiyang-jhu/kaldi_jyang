// bpe/build-bpe-on-demand-fst.cc

#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "lat/kaldi-lattice.h"
#include "lat/lattice-functions.h"
#include "bpe/deterministic-fst-bpe.h"

namespace kaldi {
class WordLexiconInfo {
 private:
  typedef typename fst::StdArc::Label Label;
  typedef typename fst::StdArc::StateId StateId;
  typedef std::unordered_map<std::vector<Label>, StateId, VectorHasher<Label> > LexiconMap;
  LexiconMap lexicon_map_;
  void UpdateLexiconMap(const std::vector<Label> &lexicon_entry);
 public:
  WordLexiconInfo(const std::vector<std::vector<Label> > &lexicon);
  void PrintLexicon(){
      for (const auto& pair : lexicon_map_){
        for (std::vector<int>::size_type i=0; i<pair.first.size(); i++){
            std::cout << " " << pair.first.at(i);
        }
        std::cout << "Value is " << pair.second << "\n";
      }
  }
  LexiconMap* ReturnLexiconMapPointer(){
    return (&lexicon_map_);
  }
};

WordLexiconInfo::WordLexiconInfo(const std::vector<std::vector<Label> >&lexicon) {
    for (size_t i = 0; i < lexicon.size(); i++) {
        const std::vector<Label> &lexicon_entry = lexicon[i];
        KALDI_ASSERT(lexicon_entry.size() >= 2);
        UpdateLexiconMap(lexicon_entry);
    }
}

void WordLexiconInfo::UpdateLexiconMap(const std::vector<Label> &lexicon_entry){
    KALDI_ASSERT(lexicon_entry.size() >= 2);
    std::vector<Label> key;
    key.reserve(lexicon_entry.size() - 1);
    key.push_back(lexicon_entry[1]);
    key.insert(key.end(), lexicon_entry.begin() + 2, lexicon_entry.end());
    StateId new_word = lexicon_entry[0];
    if (lexicon_map_.count(key) != 0) {
        if (lexicon_map_[key] == new_word)
            KALDI_WARN << "Duplicate entry in lexicon map for word " << lexicon_entry[0];
        else
            KALDI_ERR << "Duplicate entry in lexicon map for word " << lexicon_entry[0] << " with inconsistent to-word.";
    }
    lexicon_map_[key] = new_word;
}

class BPEStopWordsInfo {
  private:
    typedef typename fst::StdArc::Label Label;
    typedef std::unordered_set<int32> BPEStopSet;
    BPEStopSet bpe_stop_sets_;
    void UpdateBPEStopList(const std::vector<Label> &bpe_stop_list);
  public:
    BPEStopWordsInfo(const std::vector<Label>  &bpe_stop_list);
    void PrintBPEStopWords(){
      unordered_set<Label> :: iterator itr;
      for (itr = bpe_stop_sets_.begin(); itr != bpe_stop_sets_.end(); itr++){
        std::cout << "Value is " << (*itr) << "\n";
      }
    }
    BPEStopSet* ReturnStopWordsSetPointer(){
      return (&bpe_stop_sets_);
    }
};

BPEStopWordsInfo::BPEStopWordsInfo(const std::vector<Label> &bpe_stop_list) {
  UpdateBPEStopList(bpe_stop_list);
}

void BPEStopWordsInfo::UpdateBPEStopList(const std::vector<Label> &bpe_stop_list){
    for (size_t i = 0; i < bpe_stop_list.size(); i++) {
        bpe_stop_sets_.insert(bpe_stop_list[i]);
    }
}

bool ReadBPELexicon (std::istream &is,
                     std::vector<std::vector<fst::StdArc::Label> > *lexicon) {
   lexicon->clear();
   std::string line;
   while (std::getline(is, line)) {
     std::vector<fst::StdArc::Label> this_entry;
     if (!SplitStringToIntegers(line, " \t\r", false, &this_entry) ||
         this_entry.size() < 2) {
       KALDI_WARN << "Lexicon line '" << line  << "' is invalid";
       return false;
     }
     lexicon->push_back(this_entry);
   }
   return (!lexicon->empty());
 }

bool ReadBPEStopWords (std::istream &is,
                       std::vector<fst::StdArc::Label> *bpe_stop_list) {
  bpe_stop_list->clear();
  std::string line;
  while (std::getline(is, line)) {
    std::vector<int32> this_entry;
    SplitStringToIntegers(line, " \t\r", false, &this_entry);
    if (this_entry.size() != 1){
      KALDI_WARN << "BPE stop words list '" << line << "' is invalid";
      return false;
    }
    bpe_stop_list->push_back(this_entry[0]);
  }
  return (!bpe_stop_list->empty());
}
} //namespace
int main(int argc, char *argv[]) {
  try{
    const char *usage =
        "Convert BPE lattice to word lattice, by building a BPE OnDemandFst\n"
        "Usage: lattice-bpe-to-word [options] <subword-lexicon> "
        "<bpe-ending-list> <lattice-rspecifier> <lattice-wspecifier>\n"
        "Example of subword-lexicon: \n"
        "3 2 5 40 \n"
        "Example of bpe-ending-list: \n"
        "40\n"
        "e.g.: lattice-bpe-to-word subword_lexicon.txt bpe_ending.txt ark:bpe.lats ark:word.lats \n";
    using namespace kaldi;
    using namespace fst;
    using fst::BPEDeterministicOnDemandFst;
    using kaldi::int32;
    StdArc::Label unk_int=-1;
    ParseOptions po(usage);
    po.Register("unk-int", &unk_int, "OOV word id. Default is the max word-id+1");
    po.Read(argc, argv);
    if (po.NumArgs() != 4) {
      po.PrintUsage();
      exit(1);
    }
    std::string lexicon_rxfilename = po.GetArg(1);
    std::string bpe_stops_rxfilename = po.GetArg(2);
    std::string lats_rspecifier = po.GetArg(3);
    std::string lats_wspecifier = po.GetArg(4);
    std::vector<std::vector<fst::StdArc::Label> > lexicon;
    std::vector<fst::StdArc::Label> bpe_stop_list;
    bool binary_in, binary_in2;

    // Read lexicon and store in map
    Input ki(lexicon_rxfilename, &binary_in);
    KALDI_ASSERT(!binary_in && "Not expecting binary file for lexicon");
    if (!ReadBPELexicon(ki.Stream(), &lexicon)){
       KALDI_ERR << "Error reading alignment lexicon from "
                 << lexicon_rxfilename;
    }
    WordLexiconInfo lexicon_info(lexicon);

    // Read BPE stop words list
    Input ki2(bpe_stops_rxfilename, &binary_in2);
    KALDI_ASSERT(!binary_in2 && "Not expecting binary file for BPE stop words list");
    if (!ReadBPEStopWords(ki2.Stream(), &bpe_stop_list)){
       KALDI_ERR << "Error reading bpe stop word list from "
                 << bpe_stops_rxfilename;
    }
    BPEStopWordsInfo bpe_stop_words_info(bpe_stop_list);

    SequentialCompactLatticeReader compact_lattice_reader(lats_rspecifier);
    CompactLatticeWriter compact_lattice_writer(lats_wspecifier);

    typedef std::unordered_map<std::vector<fst::StdArc::Label>, fst::StdArc::Label,
                               VectorHasher<fst::StdArc::Label> > LexiconMap;
    typedef std::unordered_set<fst::StdArc::Label> BPEStopSet;
    LexiconMap *lexicon_pointer = lexicon_info.ReturnLexiconMapPointer();
    BPEStopSet *bpe_stop_pointer = bpe_stop_words_info.ReturnStopWordsSetPointer();
   //  Begin to build BPEOnDemandFst
		int32 n_done = 0, n_fail = 0;
    for (; !compact_lattice_reader.Done(); compact_lattice_reader.Next()) {
      std::string key = compact_lattice_reader.Key();
      CompactLattice &clat = compact_lattice_reader.Value();
      ArcSort(&clat, fst::OLabelCompare<CompactLatticeArc>());
      BPEDeterministicOnDemandFst bpe_lex_fst(lexicon_pointer, bpe_stop_pointer, unk_int);
      CompactLattice composed_clat;
      ComposeCompactLatticeDeterministic(clat, &bpe_lex_fst, &composed_clat);
      Project(&composed_clat, fst::PROJECT_OUTPUT);
      Lattice composed_lat;
      ConvertLattice(composed_clat, &composed_lat);

      // Determinizes the composed lattice.
      Invert(&composed_lat);
      CompactLattice determinized_clat;
		  DeterminizeLattice(composed_lat, &determinized_clat);
      if (determinized_clat.Start() == fst::kNoStateId) {
        KALDI_WARN << "Empty lattice for utterance " << key;
        n_fail++;
      } else {
        compact_lattice_writer.Write(key, determinized_clat);
        n_done++;
      }
    }
  } catch(const std::exception &e) {
      std::cerr << e.what();
      return -1;
  }
}
