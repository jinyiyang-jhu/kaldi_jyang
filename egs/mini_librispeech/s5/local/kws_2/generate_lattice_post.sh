align_mdl="exp/chain/tri3b_train_clean_5_sp_lats/final.mdl"
mdl="exp/chain/tdnn1h_sp/final.mdl"
lang="data/lang_test_tgsmall"
result_file="test_data_dir/results_v3/test.results"

ref_lattice="test_data_dir/dev_ali_word_all.lats"
ref_1best_word_post="test_data_dir/dev_ali_1best_word.post"
hyp_lattice="test_data_dir/dev_chain_word_all.lats"
hyp_word_post="test_data_dir/dev_chain_word_all.post"

# Generate lattice from alignments:
#steps/align_fmllr_lats.sh $ref_lattice
#lattice-1best ark:$ref_lattice ark:-|\
#    lattice-align-words $lang/phones/word_boundary.int $align_mdl ark:- ark:-| \
#    lattice-arc-post $align_mdl ark:- $ref_1best_word_post

ref_lats="lattice-1best ark:$ref_lattice ark:- | lattice-align-words \
    $lang/phones/word_boundary.int $align_mdl ark:- ark:- |"

# Generate post from lattice
#lattice-align-words $lang/phones/word_boundary.int $mdl \
#    ark:$hyp_lattice ark:- | lattice-arc-post $mdl ark:- $hyp_word_post
hyp_lats="lattice-align-words $lang/phones/word_boundary.int $mdl \
    ark:$hyp_lattice ark:- |"

#python3 local/kws_2/compute_precison_recall_lattice-final.py \
#    <(lattice-arc-post $align_mdl ark:"$ref_lats" - | sort) \
#    <(lattice-arc-post $align_mdl ark:"$hyp_lats" - | sort) \
#    > test_data_dir/results_v3/test.result

python3 local/kws_2/compute_precision_recall_lattice-final.py \
    <(lattice-arc-post $align_mdl ark:"$ref_lats" - | sort) \
    <(lattice-arc-post $align_mdl ark:"$hyp_lats" - | sort) \
    > $result_file
