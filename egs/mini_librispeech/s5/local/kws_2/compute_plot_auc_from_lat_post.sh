#!/bin/bash


lattice_type="word"
chain_model="" # "--chain_model"

[ -f path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 5 ];then
    echo "Usage: $0 [--lattice-type word | phone ] [ --chain-model ] <data-dir> <lang> <align-dir> <decode-dir> <result-dir>"
    exit 1
fi
data_dir=$1
lang=$2
align_dir=$3
decode_dir=$4
result_dir=$5

decode_mdl="$(dirname $decode_dir)/final.mdl"
[ ! -f $decode_dir/lat.1.gz ] && echo "Decoding lattice does not exist !" && exit 1;

[ -d $result_dir ] || mkdir -p $result_dir || exit 1;

nj=`ls $decode_dir/lat.*.gz | wc -l`

if [ `ls $align_dir/lat.*.gz | wc -l` -ne $nj ]; then
    echo "Align does not exist, or align.*.gz number not equal to lat.*.gz,\
    run steps/align_fmllr_lats.sh with --nj $nj ..."
    exit 1;
fi

for i in $(seq $nj); do
    if [ $lattice_type == "word" ]; then
        ref_lats="lattice-1best ark:\"gunzip -c $align_dir/lat.$i.gz|\" ark:- | lattice-align-words $lang/phones/word_boundary.int $align_dir/final.mdl ark:- ark:- |"
        hyp_lats="lattice-align-words $lang/phones/word_boundary.int $decode_mdl ark:\"gunzip -c $decode_dir/lat.$i.gz |\" ark:- |"
    elif [ $lattice_type == "phone" ]; then
        ref_lats="lattice-1best ark:\"gunzip -c $align_dir/lat.$i.gz|\" ark:- | lattice-align-phones --replace-output-symbols=true $align_dir/final.mdl ark:- ark:- |"
        hyp_lats="lattice-align-phones --replace-output-symbols=true $decode_mdl ark:\"gunzip -c $decode_dir/lat.$i.gz |\" ark:- |"
    fi
    python3 local/kws_2/compute_auc_scores.py \
        $chain_model \
        <(lattice-arc-post $align_dir/final.mdl ark:"$ref_lats" - | sort) \
        <(lattice-arc-post $decode_mdl ark:"$hyp_lats" - | sort) \
        > $result_dir/auc_scores.$i.txt
done
cat $result_dir/auc_scores.*.txt > $result_dir/auc_scores.txt
rm $result_dir/auc_scores.*.txt

python3 local/kws_2/compute_plot_auc.py $result_dir/auc_scores.txt $result_dir/auc.png
