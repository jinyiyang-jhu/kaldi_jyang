
# Generate lattice from alignments:
steps/align_fmllr_lats.sh $ref_lattice
lattice-1best $ref_lattice $ref_1best_lattice

# Generate post from lattice (both ref and hyp)
lattice-align-words $ori_lat $new_lat
lattice-arc-post $new_lat $output_post

