#!/bin/bash

. ./path.sh
. ./utils/parse_options.sh
. cmd.sh

mdldir=exp/nnet5c
srcdata=data_babble_noise/test_eval92_noise_babble_snr
pdf_phone_map=nnet5c_phone_mapping/pdf_to_pseudo_phone.txt  # pdf-id to phone-id map
postdir=post/nnet5c/nnet_test_eval92_noise_babble
feat_type="lda"
apply_log="false"
no_softmax="false"
name=$(basename $srcdata)
cmd=$decode_cmd
nj=8

while read s
do
echo "SNR is $s"
data=${srcdata}_${s}
p_dir=$postdir/snr_${s}

if [ ! -d $p_dir ];then
	mkdir -p $p_dir
fi


if [ $feat_type == "lda" ]; then
	splice_opts=`cat $mdldir/splice_opts 2>/dev/null`
	feats="ark,s,cs:apply-cmvn --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:$data/feats.scp ark:- | splice-feats $splice_opts $splice_opts ark:- ark:- | transform-feats $mdldir/final.mat ark:- ark:- |"
	#feats="ark,s,cs:apply-cmvn --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp scp:$data/feats.scp ark:- |"
else
	feats="$data/feats.scp"
fi

if [ $no_softmax == "true" ]; then
	mdl=$mdldir/final_no_softmax.mdl
else
	mdl=$mdldir/final.mdl
fi

$cmd JOB=1:$nj $p_dir/log/nnet_am_compute.JOB.log \
nnet-am-compute --apply-log="$apply_log" $mdl "$feats" \
ark,t:$p_dir/raw_pdf.JOB.post.matrix || exit 1;

$cmd JOB=1:$nj $p_dir/log/transform.JOB.log \
transform-nnet-posteriors --pdf-to-pseudo-phone=$pdf_phone_map \
ark:$p_dir/raw_pdf.JOB.post.matrix \
ark,t:- | sed 's/^[ \t]*//' | sed 's/[ \t]*$//' > $p_dir/monophone.JOB.post

rm $p_dir/raw_pdf.*.post.matrix
#ark,t:$p_dir/raw_monophone.JOB.post.matrix || exit 1;
#cat $p_dir/raw_monophone.*.post.matrix | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'> $p_dir/monophone.post.matrix
#python tools/post_from_nnet/convert_post_to_kaldi_post.py $postdir/monophone.post.matrix $postdir/monophone.post.kd.matrix "merge"


done < snr_utgpr_5k_flat.list
exit 0;
