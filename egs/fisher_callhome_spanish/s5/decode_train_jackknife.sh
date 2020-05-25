#!/bin/bash

# Create a decoding graph, use the acoustic model trained on whole training
# data, while LM is trained on (k-1)/k of the whole training data. Decode the
# whole training data with the new decoding graph to get lattices of training
# data, used for training Lattice Transformer.

stage=2
nj=64
k_fold=10
text_dir=data/train
train_dir=data/train_sp_hires
ivec_train_dir=exp/nnet3/ivectors_train_sp_hires
tree_dir=exp/chain/tri5a_tree
full_lang_dir=data/lang
lang_name="data/lang_test_"
graph_name="graph_fsp_train_"
decode_dir="exp/chain/multipsplice_tdnn/decode_train_${graph_name}${k_fold}_folds_"
result_dir="jackknife_train_${k_fold}_folds_wer"
. cmd.sh
. path.sh

tot_sets=($(seq $k_fold))
lang_dir=${lang_name}${k_fold}_folds
graph_dir=$tree_dir/${graph_name}${k_fold}_folds
decode_data_dir=${text_dir}_hires_${k_fold}_folds
ivec_dir=${ivec_train_dir}_${k_fold}_folds
decode_dir=${decode_dir}${k_fold}_folds_
lexicon=data/local/dict/lexicon.txt
if [ ! -d $text_dir/split${k_fold} ]; then
  echo "Creating $k_fold subsets of training text"
  utils/split_data.sh data/train $k_fold || exit 1;
fi
mkdir -p $lang_dir || exit 1;
mkdir -p $graph_dir || exit 1;
mkdir -p $decode_data_dir || exit 1;
mkdir -p $ivec_dir || exit 1;
mkdir -p $result_dir || exit 1;
[ -f $result_dir/hyp.txt ] && rm $result_dir/hyp.txt
ref_filtering_cmd="cat"
[ -x local/wer_output_filter ] && ref_filtering_cmd="local/wer_output_filter"
cat $text_dir/text | $ref_filtering_cmd > $result_dir/test_filt.txt || exit 1;

for k in ${tot_sets[@]}; do
  echo "Processing $k fold"
  new_lang=${lang_dir}/$k
  mkdir -p $new_lang

  if [ $stage -le 0 ]; then
    echo "Step 1: Preparing LM"
    cp -r $full_lang_dir/* $new_lang
    cp data/local/lm/word_map $new_lang
    [ -f $new_lang/text ] && rm $new_lang/text
    for i in ${tot_sets[@]}; do
      if [ $i -ne $k ]; then
        cat $text_dir/split${k_fold}/$i/text >> $new_lang/text || exit 1;
      fi
    done
    cleantext=$new_lang/text.no_oov
    text=$new_lang/text
    cat $text | awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } }
      {for(n=1; n<=NF;n++) {  if (seen[$n]) { printf("%s ", $n); } else {printf("<unk> ");} } printf("\n");}' \
      > $cleantext || exit 1;
    cat $cleantext | awk -v wmap=$new_lang/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
      { for(n=2;n<=NF;n++) { printf map[$n]; if(n<NF){ printf " "; } else { print    ""; }}}' | gzip -c >$new_lang/train.gz \
      || exit 1;
    echo "Step 1: Preparing LM => training LM"
    train_lm.sh --arpa --lmtype 3gram-mincount $new_lang || exit 1;
    echo "Step 1: Preparing LM => done !"
  fi

  arpa_lm=$new_lang/3gram-mincount/lm_unpruned.gz
  [ ! -f $arpa_lm ] && echo "No such file $arpa_lm" && exit 1;
  new_graph=${graph_dir}/$k
  if [ $stage -le 1 ]; then
    echo "Step 2: Build HCLG => G.fst"
    gunzip -c "$arpa_lm" | \
      arpa2fst --disambig-symbol=#0 --read-symbol-table=$new_lang/words.txt - $new_lang/G.fst
    fstisstochastic $new_lang/G.fst
    fstdeterminize $new_lang/G.fst /dev/null || echo Error determinizing G.
    fsttablecompose $new_lang/L_disambig.fst $new_lang/G.fst | \
    fstdeterminizestar >/dev/null || echo Error
    fsttablecompose $new_lang/L_disambig.fst $new_lang/G.fst | \
    fstisstochastic || echo "[log:] LG is not stochastic"

    utils/mkgraph.sh \
      --self-loop-scale 1.0 $new_lang \
      $tree_dir $new_graph || exit 1;
    echo "Step 2: Build HCLG => done !"
  fi

decode_sub_data=$decode_data_dir/$k
ivec_sub_dir=$ivec_dir/$k
  if [ $stage -le 2 ]; then
    echo "Step 3: Decoding"
    iter_opts=
    # Create the subsets from speed pertubated data of k_folds, corresponding
    # to the utterances in the text_dir/split_${k_fold}
    mkdir -p $decode_sub_data
    mkdir -p $ivec_sub_dir
    for f in text wav.scp; do
      cp $text_dir/split${k_fold}/$k/$f $decode_sub_data || exit 1;
    done
    cp $train_dir/frame_shift $decode_sub_data || exit 1;
    for f in feats.scp segments utt2dur utt2num_frames utt2spk utt2uniq; do
      awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $decode_sub_data/text $train_dir/$f > $decode_sub_data/$f
    done
    perl utils/utt2spk_to_spk2utt.pl $decode_sub_data/utt2spk > $decode_sub_data/spk2utt
    for f in cmvn.scp reco2dur reco2file_and_channel spk2gender; do
      awk 'NR==FNR{a[$1];next} $1 in a{print $0}' $decode_sub_data/spk2utt $train_dir/$f > $decode_sub_data/$f
    done
    cp $ivec_train_dir/ivector_period $ivec_sub_dir
    cp $ivec_train_dir/final.ie.id $ivec_sub_dir
    awk 'NR==FNR{a[$1];next} $1 in a{print $0}' \
      $decode_sub_data/utt2spk $ivec_train_dir/ivector_online.scp > $ivec_sub_dir/ivector_online.scp

    steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
	    --nj $nj --cmd "$decode_cmd" $iter_opts \
	    --online-ivector-dir "$ivec_sub_dir" \
	    $new_graph $decode_sub_data ${decode_dir}${k} || exit 1
    #echo "Step 3: Decoding => RNN rescoring"
    #pruned=_pruned
    #rnnlmdir=exp/rnnlm_lstm_tdnn_1b
    #rnnlm/lmrescore$pruned.sh \
    #  --cmd "$decode_cmd --mem 8G" \
    #  --weight 0.45 --max-ngram-order 4 \
    #  $lang_dir $rnnlmdir \
    #  $train_dir ${decode_dir} \
    #  ${decode_dir}_rnn_lstm_tdnn_1b_rescore || exit 1
    echo "Step 3: Decoding => done!"
  fi

	best_wer_file=$(awk '{print $NF}' ${decode_dir}${k}/scoring_kaldi/best_wer)
	best_wip=$(echo $best_wer_file | awk -F_ '{print $NF}')
	best_lmwt=$(echo $best_wer_file | awk -F_ '{N=NF-1; print $N}')
	cat ${decode_dir}${k}/scoring_kaldi/penalty_${best_wip}/$best_lmwt.txt >> $result_dir/hyp.txt 
  stage=-1
done

cat $result_dir/hyp.txt | sort | \
	compute-wer --text --mode=present \
	ark:$result_dir/test_filt.txt ark:- > $result_dir/wer || exit 1;


