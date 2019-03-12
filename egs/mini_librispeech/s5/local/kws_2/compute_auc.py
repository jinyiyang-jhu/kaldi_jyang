#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Apache 2.0

# This script computes the minimum detection cost function, which is a common
# error metric used in speaker recognition.  Compared to equal error-rate,
# which assigns equal weight to false negatives and false positives, this
# error-rate is usually used to assess performance in settings where achieving
# a low false positive rate is more important than achieving a low false
# negative rate.  See the NIST 2016 Speaker Recognition Evaluation Plan at
# https://www.nist.gov/sites/default/files/documents/2016/10/07/sre16_eval_plan_v1.3.pdf
# for more details about the metric.
from __future__ import print_function
from operator import itemgetter
import sys, argparse, os
import numpy as np

try:
    import matplotlib as mpl
    mpl.use('Agg')
    import matplotlib.pyplot as plt
except ImportError:
    raise ImportError(
        """This script requires matplotlib.
        Please install it to generate plots.
        If you are on a cluster where you do not have admin rights you could
        try using virtualenv.""")
 

def GetArgs():
    parser = argparse.ArgumentParser(description="Compute the precision-recall"
        "and area under curve (AUC)"
        "Usage: sid/compute_auc.py [options...] <scores-file> "
        "<trials-file> "
        "E.g., sid/compute_min_dcf.py --wake-word '嗨小问' "
        "exp/scores/trials data/test/trials",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--wake-word', type=str, dest = "wake_word", default = '嗨小问', help="wake word")
    parser.add_argument("trials_filename",
        help="Input trials file, with columns of the form "
        "<utt-id> <wake-word> or None")
    parser.add_argument("scores_filename", type=str, nargs='+',
        help="List of input scores file, with columns of the form "
        "<utt-id> <score>")
    sys.stderr.write(' '.join(sys.argv) + "\n")
    args = parser.parse_args()
    args = CheckArgs(args)
    return args

def CheckArgs(args):
    if (args.scores_filename is not None and len(args.scores_filename) > 6):
        raise Exception(
            """max 6 scores filenames can be specified.
            If you want to compare with more, you would have to
            carefully tune the plot_colors variable which specified colors used
            for plotting.""")
    return args

# Creates a list of false-negative rates, a list of false-positive rates
# and a list of decision thresholds that give those error-rates.
def ComputePrecisionRecall(scores, labels):

      # Sort the scores from smallest to largest, and also get the corresponding
      # indexes of the sorted scores.  We will treat the sorted scores as the
      # thresholds at which the the error-rates are evaluated.
      sorted_indexes, thresholds = zip(*sorted(
          [(index, threshold) for index, threshold in enumerate(scores)],
          key=itemgetter(1)))
      sorted_labels = []
      labels = [labels[i] for i in sorted_indexes]
      fn = []
      tn = []
      precision = []
      recall = []
      # At the end of this loop, fn[i] is the number of errors made by
      # incorrectly rejecting scores less than thresholds[i]. And, tn[i]
      # is the total number of times that we have correctly rejected scores
      # less than thresholds[i].
      for i in range(0, len(labels)):
          if i == 0:
              fn.append(labels[i])
              tn.append(1 - labels[i])
          else:
              fn.append(fn[i-1] + labels[i])
              tn.append(tn[i-1] + 1 - labels[i])
      fn_norm = sum(labels)
      tn_norm = len(labels) - fn_norm
      tp = [fn_norm - x for x in fn]
      fp = [tn_norm - x for x in tn]
      # Compute precision and recall rate.
      for i, j in enumerate(tp):
          tp_norm = float(j + fp[i])
          if tp_norm > 0 :
              precision.append(j / tp_norm)
              recall.append(j / fn_norm)
              print(f'recall: {recall[i]} , precision: {precision[i]}')
      auc = np.abs(np.trapz(precision, recall))
      return precision, recall, auc

# Computes the minimum of the detection cost function.  The comments refer to
# equations in Section 3 of the NIST 2016 Speaker Recognition Evaluation Plan.
def ComputeMinDcf(fnrs, fprs, thresholds, p_target, c_miss, c_fa):
    min_c_det = float("inf")
    min_c_det_threshold = thresholds[0]
    for i in range(0, len(fnrs)):
        # See Equation (2).  it is a weighted sum of false negative
        # and false positive errors.
        c_det = c_miss * fnrs[i] * p_target + c_fa * fprs[i] * (1 - p_target)
        if c_det < min_c_det:
            min_c_det = c_det
            min_c_det_threshold = thresholds[i]
    # See Equations (3) and (4).  Now we normalize the cost.
    c_def = min(c_miss * p_target, c_fa * (1 - p_target))
    min_dcf = min_c_det / c_def
    return min_dcf, min_c_det_threshold

def PlotRoc(precision_list, recall_list, auc_list, color_val_list, name_list, savedir):
    assert len(recall_list) == len(precision_list) and \
        len(recall_list) == len(color_val_list) and \
        len(recall_list) == len(name_list) and \
        len(recall_list) == len(auc_list)
    fig = plt.figure()
    roc_plots = []
    for i in range(len(recall_list)):
        recall = recall_list[i]
        precision = precision_list[i]
        auc = auc_list[i]
        color_val = color_val_list[i]
        name = name_list[i]
        roc_plot_handle, = plt.plot([rec * 100 for rec in recall],
            [prec * 100 for prec in precision], color=color_val,
            linestyle="--",
            label="auc={:.4f}".format(auc)
        )
        roc_plots.append(roc_plot_handle)

    plt.xlabel('Recall (%)')
    plt.ylabel('Precision (%)')
    plt.xlim([0, 103])
    plt.ylim([0, 103])
    lgd = plt.legend(handles=roc_plots, loc='lower center',
        bbox_to_anchor=(0.5, -0.2 + len(recall_list) * -0.1),
        ncol=1, borderaxespad=0.)
    plt.grid(True)
    fig.suptitle("Precision-recall curve")
    figfile_name = os.path.join(savedir, 'auc_curve.pdf')
    plt.savefig(figfile_name, bbox_extra_artists=(lgd,), bbox_inches='tight')
    print("Saved AUC curves as " + figfile_name)

def main():
    args = GetArgs()
    g_plot_colors = ['red', 'blue', 'green', 'black', 'magenta', 'yellow']
    trials_file = open(args.trials_filename, 'r', encoding='utf-8').readlines()

    trials = {}
    for line in trials_file:
        if len(line.rstrip().split()) == 2:
            utt_id, target = line.rstrip().split()
        else:
            assert len(line.rstrip().split()) == 1
            utt_id = line.rstrip().split()[0]
            target = ""
        trials[utt_id] = target

    precision_list, recall_list, auc_list, color_val_list, name_list = [], [],[], [], []
    savedir = os.path.dirname(args.scores_filename[0])
    for index, path in enumerate(args.scores_filename):
        scores = []
        labels = []
        scores_file = open(path, 'r', encoding='utf-8').readlines()
        for line in scores_file:
            utt_id, score = line.rstrip().split()
            if utt_id in trials:
                scores.append(float(score))
                if trials[utt_id] == args.wake_word:
                    labels.append(1)
                else:
                    labels.append(0)
            else:
                raise Exception("Missing entry for " + utt_id
                    + " " + path)

        precision, recall, auc = ComputePrecisionRecall(scores, labels)
        precision_list.append(precision)
        recall_list.append(recall)
        auc_list.append(auc)
        color_val_list = g_plot_colors[:len(args.scores_filename)]
        name_list.append(os.path.dirname(path))

    PlotRoc(precision_list, recall_list, auc_list, color_val_list, name_list, savedir)

if __name__ == "__main__":
  main()
