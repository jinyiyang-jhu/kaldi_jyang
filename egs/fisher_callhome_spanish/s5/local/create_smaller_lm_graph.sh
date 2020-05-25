#!/bin/bash

# Create a decoding graph, use the acoustic model trained on whole training
# data, while LM is trained on (k-1)/k of the whole training data. Decode the
# whole training data with the new decoding graph to get lattices of training
# data, used for training Lattice Transformer.

text_dir=data/train
train_dir=data/train_sp_hires
ivec_dir=exp/nnet3/ivectors_train_sp_hires
tree_dir=exp/chain/tri5a_tree
lang_dir=data/lang_test_10_folds
full_lang_dir=data/lang
graph_name=graph_fsp_train_10_folds
decode_dir=exp/chain/multipsplice_tdnn/decode_train_${graph_name}
total_folds=30
k_fold=3 #(10-fold, already exists data/train/split100, so take the first 100-10 splits as 9/10 folds for training new LM)
stage=2
nj=80
graph_dir=$tree_dir/$graph_name

. cmd.sh
. path.sh

mkdir -p $lang_dir
cp -r $full_lang_dir/* $lang_dir
cp data/local/lm/word_map $lang_dir
if [ $stage -le 0 ]; then
  echo "Step 1: Preparing LM"
  [ -f $lang_dir/text ] && rm $lang_dir/text
  [ -f $lang_dir/${k_fold}_fold_splits.count ] && rm $lang_dir/${k_fold}_fold_splits.count
  # Create a random list with $total splits, keep the first $total-$k as training sets
  tot_arr=($(seq $total_folds))
  tot_arr=( $(shuf -e "${tot_arr[@]}") )
  sub_array=( ${tot_arr[@]:$k_fold})
  for i in ${sub_array[@]}; do
    echo $i >> $lang_dir/${k_fold}_fold_splits.count
    cat $text_dir/split${total_folds}/$i/text >> $lang_dir/text || exit 1;
  done

  lexicon=data/local/dict/lexicon.txt
  cleantext=$lang_dir/text.no_oov
  text=$lang_dir/text

  cat $text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } }
    {for(n=1; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<unk> ");} } printf("\n");}' \
    > $cleantext || exit 1;

  #cat $cleantext | awk '{for(n=2;n<=NF;n++) print $n; }' | sort | uniq -c | \
  #   sort -nr > $lang_dir/word.counts || exit 1;

  #cat $cleantext | awk '{for(n=2;n<=NF;n++) print $n; }' | \
  #  cat - <(grep -w -v '!SIL' $lexicon | awk '{print $1}') | \
  #   sort | uniq -c | sort -nr > $lang_dir/unigram.counts || exit 1;

  #cat $lang_dir/unigram.counts  | awk '{print $2}' | get_word_map.pl "<s>" "</s>" "<unk>" > $lang_dir/word_map \
  #   || exit 1;

  cat $cleantext | awk -v wmap=$lang_dir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
    { for(n=2;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print    ""; }}}' | gzip -c >$lang_dir/train.gz \
     || exit 1;
  echo "Step 1: Preparing LM => training LM"
  train_lm.sh --arpa --lmtype 3gram-mincount $lang_dir || exit 1;
  echo "Step 1: Preparing LM => done !"
fi

arpa_lm=$lang_dir/3gram-mincount/lm_unpruned.gz
[ ! -f $arpa_lm ] && echo "No such file $arpa_lm" && exit 1;

if [ $stage -le 1 ]; then
  echo "Step 2: Build HCLG => G.fst" 

  gunzip -c "$arpa_lm" | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$full_lang_dir/words.txt - $lang_dir/G.fst
  fstisstochastic $lang_dir/G.fst
  fstdeterminize $lang_dir/G.fst /dev/null || echo Error determinizing G.
fsttablecompose $lang_dir/L_disambig.fst $lang_dir/G.fst | \
   fstdeterminizestar >/dev/null || echo Error

  fsttablecompose $lang_dir/L_disambig.fst $lang_dir/G.fst | \
   fstisstochastic || echo "[log:] LG is not stochastic"

   utils/mkgraph.sh \
    --self-loop-scale 1.0 $lang_dir \
    $tree_dir $graph_dir || exit 1;
   echo "Step 2: Build HCLG => done !"
fi

if [ $stage -le 2 ]; then
  echo "Step 3: Decoding"
  iter_opts=
  #steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	#  --nj $nj --cmd "$decode_cmd" $iter_opts \
	#  --online-ivector-dir "$ivec_dir" \
	#  $graph_dir $train_dir $decode_dir || exit 1
  echo "Step 3: Decoding => RNN rescoring"
  pruned=_pruned
  rnnlmdir=exp/rnnlm_lstm_tdnn_1b
  rnnlm/lmrescore$pruned.sh \
    --cmd "$decode_cmd --mem 8G" \
    --weight 0.45 --max-ngram-order 4 \
    $lang_dir $rnnlmdir \
    $train_dir ${decode_dir} \
    ${decode_dir}_rnn_lstm_tdnn_1b_rescore || exit 1
  echo "Step 3: Decoding => done!"
fi
