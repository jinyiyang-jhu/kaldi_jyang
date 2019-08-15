// fstext/build-bpe-on-demand-fst.cc

#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "lat/kaldi-lattice.h"
#include "lat/word-align-lattice-lexicon.h"
#include "lat/lattice-functions.h"
#include "fstext/deterministic-fst-bpe.h"

namespace kaldi {

const int kTemporaryEpsilon = -2;
class WordLexiconInfo {
 private:
  typedef std::unordered_map<std::vector<int32>, int32, VectorHasher<int32> > LexiconMap;
  LexiconMap lexicon_map_;
  void UpdateLexiconMap(const std::vector<int32> &lexicon_entry);
 public:
  WordLexiconInfo(const std::vector<std::vector<int32> > &lexicon);
  void PrintLexicon(){
      for (const auto& pair : lexicon_map_){
        for (std::vector<int>::size_type i=0; i<pair.first.size(); i++){
            std::cout << " " << pair.first.at(i);
        }
        std::cout << "Value is " << pair.second << "\n";
      }
  }
  bool ReturnLexiconMap(LexiconMap *lexicon_pointer){
    lexicon_pointer = &lexicon_map_;
    return (!lexicon_pointer->empty());
  }
};

WordLexiconInfo::WordLexiconInfo(const std::vector<std::vector<int32> >&lexicon) {
    for (size_t i = 0; i < lexicon.size(); i++) {
        const std::vector<int32> &lexicon_entry = lexicon[i];
        KALDI_ASSERT(lexicon_entry.size() >= 2);
        UpdateLexiconMap(lexicon_entry);
    }
}

void WordLexiconInfo::UpdateLexiconMap(const std::vector<int32> &lexicon_entry){
    KALDI_ASSERT(lexicon_entry.size() >= 2);
    std::vector<int32> key;
    key.reserve(lexicon_entry.size() - 1);
    key.push_back(lexicon_entry[1]);
    key.insert(key.end(), lexicon_entry.begin() + 2, lexicon_entry.end());
    int32 new_word = lexicon_entry[0];
    //if (new_word == 0) new_word = kTemporaryEpsilon;
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
    typedef std::unordered_set<int32 > BPEStopSet;
    BPEStopSet bpe_stop_sets_;
    void UpdateBPEStopList(const std::vector<int32> &bpe_stop_list);
  public:
    BPEStopWordsInfo(const std::vector<int32>  &bpe_stop_list);
    void PrintBPEStopWords(){
      unordered_set<int32> :: iterator itr;
      for (itr = bpe_stop_sets_.begin(); itr != bpe_stop_sets_.end(); itr++){
        std::cout << "Value is " << (*itr) << "\n";
      }
    }
    bool ReturnStopWordsSet(BPEStopSet *bpe_stop_pointer){
      bpe_stop_pointer = &bpe_stop_sets_;
      return (!bpe_stop_pointer->empty());
    }

};

BPEStopWordsInfo::BPEStopWordsInfo(const std::vector<int32> &bpe_stop_list) {
  UpdateBPEStopList(bpe_stop_list);
}

void BPEStopWordsInfo::UpdateBPEStopList(const std::vector<int32> &bpe_stop_list){
    for (size_t i = 0; i < bpe_stop_list.size(); i++) {
        bpe_stop_sets_.insert(bpe_stop_list[i]);
    }
}

bool ReadBPEStopWords (std::istream &is,
                       std::vector<int32> *bpe_stop_list) {
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
				"with BPE lattice and lexicon, then compose this FST with given lattice.\n"
        "Usage: build-bpe-on-demand-fst [options] <lexicon> \\\n"
				"<lattice-rspecifier> <lattice-wspecifier>\n"
        " e.g.: build-bpe-on-demand-fst "
        "    data/local/dict_bpe/lexicon.int data/lang/bpe_stop_sym.txt ark:in.lats ark:out.lats \\\n";
        using namespace kaldi;
        using namespace fst;
        using kaldi::int32;
    ParseOptions po(usage);
    po.Read(argc, argv);
    if (po.NumArgs() != 4) {
      po.PrintUsage();
      exit(1);
    }
    std::string lexicon_rxfilename = po.GetArg(1);
    std::string bpe_stops_rxfilename = po.GetArg(2);
    std::string lats_rspecifier = po.GetArg(3);
    std::string lats_wspecifier = po.GetArg(4);
    std::vector<std::vector<int32> > lexicon;
    std::vector<int32> bpe_stop_list;
    bool binary_in, binary_in2;

    // Read lexicon and store in map
    Input ki(lexicon_rxfilename, &binary_in);
    KALDI_ASSERT(!binary_in && "Not expecting binary file for lexicon");
    if (!ReadLexiconForWordAlign(ki.Stream(), &lexicon)){
       KALDI_ERR << "Error reading alignment lexicon from "
                 << lexicon_rxfilename;
    }
    WordLexiconInfo lexicon_info(lexicon);
    //lexicon_info.PrintLexicon();

    // Read BPE stop words list
    Input ki2(bpe_stops_rxfilename, &binary_in2);
    KALDI_ASSERT(!binary_in2 && "Not expecting binary file for BPE stop words list");
    if (!ReadBPEStopWords(ki2.Stream(), &bpe_stop_list)){
       KALDI_ERR << "Error reading bpe stop word list from "
                 << bpe_stops_rxfilename;
    }
    BPEStopWordsInfo bpe_stop_words_info(bpe_stop_list);
    // bpe_stop_words_info.PrintBPEStopWords();

    SequentialCompactLatticeReader compact_lattice_reader(lats_rspecifier);
    CompactLatticeWriter compact_lattice_write(lats_wspecifier);

    // Begin to build BPEOnDemandFst
   for (; !compact_lattice_reader.Done(); compact_lattice_reader.Next()) {
     std::string key = compact_lattice_reader.Key();
     CompactLattice &clat = compact_lattice_reader.Value();
     ArcSort(&clat, fst::OLabelCompare<CompactLatticeArc>());
     typedef std::unordered_map<std::vector<int32>, int32, VectorHasher<int32> > LexiconMap;
     typedef std::unordered_set<int32 > BPEStopSet;
     LexiconMap *lexicon_pointer;
     BPEStopSet *bpe_stop_pointer;
     if (lexicon_info.ReturnLexiconMap(lexicon_pointer) && bpe_stop_words_info(bpe_stop_pointer) ) {
     BPEDeterministicOnDemandFst<fst::StdArc> bpe_lex_fst(lexicon_pointer,
                                                      bpe_stop_pointer);
     }
     //BPEDeterministicOnDemandFst<fst::StdArc> bpe_lex_fst;
    }
    lexicon.clear();
    bpe_stop_list.clear();
    } catch(const std::exception &e) {
      std::cerr << e.what();
      return -1;
    }
}
