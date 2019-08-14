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
 protected:
  typedef std::unordered_map<std::vector<int32>, int32, VectorHasher<int32> > LexiconMap;
  LexiconMap lexicon_map_;
  void UpdateLexiconMap(const std::vector<int32> &lexicon_entry);
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
} //namespace
int main(int argc, char *argv[]) {
    try{
     const char *usage =
        "Convert BPE lattice to word lattice, by building a BPE OnDemandFst\n"
				"with BPE lattice and lexicon, then compose this FST with given lattice.\n"
        "Usage: build-bpe-on-demand-fst [options] <lexicon> \\\n"
				"<lattice-rspecifier> <lattice-wspecifier>\n"
        " e.g.: build-bpe-on-demand-fst "
        "    data/local/dict_bpe/lexicon.int ark:in.lats ark:out.lats \\\n"
        using namespace kaldi;
        using kaldi::int32;
        const char *usage =
        "Test reading the lexicon file and latstream";
    ParseOptions po(usage);
    po.Read(argc, argv);
    if (po.NumArgs() != 3) {
      po.PrintUsage();
      exit(1);
    }
    std::string lexicon_rxfilename = po.GetArg(1);
    std::string lats_rspecifier = po.GetArg(2);
    std::string lats_wspecifier = po.GetArg(3);
    std::vector<std::vector<int32> > lexicon;
    bool binary_in;

    // Read lexicon and store in map
    Input ki(lexicon_rxfilename, &binary_in);
    KALDI_ASSERT(!binary_in && "Not expecting binary file for lexicon");
    if (!ReadLexiconForWordAlign(ki.Stream(), &lexicon)){
       KALDI_ERR << "Error reading alignment lexicon from "
                 << lexicon_rxfilename;
    }
    WordLexiconInfo lexicon_info(lexicon);
    SequentialCompactLatticeReader compact_lattice_reader(lats_rspecifier);
    CompactLatticeWrite compact_lattice_write(lats_wspecifier);
    //lexicon_info.PrintLexicon();
    { std::vector<std::vector<int32> > temp; lexicon.swap(temp); }
    } catch(const std::exception &e) {
      std::cerr << e.what();
      return -1;
    }
}
