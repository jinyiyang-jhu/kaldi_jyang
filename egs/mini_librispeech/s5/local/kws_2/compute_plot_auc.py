
import sys
import argparse
import numpy as np

try:
    import matplotlib as mpl
    mpl.use('Agg')
    import matplotlib.pyplot as plt
except ImportError:
    raise ImportError('''This script requires matplotlib.''')

def read_search_results(result_fname):
    '''Read search results file and store the results for each word in reference.'''
    labels = []
    scores = []
    with open(result_fname, 'r') as fid:
        for line in fid.readlines():
            tokens = line.strip().split()
            uttid = tokens.pop(0)
            ref_word = tokens[0]
            if (tokens[1] == "<eps>"):
                label = 1
            else:
                label = int(tokens[0]==tokens[1])
            score = float(tokens[2])
            labels.append(label)
            scores.append(score)
    return np.array(labels), np.array(scores)

def filter_score(labels, scores):
    indexes = np.where(scores >= 0)
    return labels[indexes], scores[indexes]

def compute_precision_recall(scores, labels):
    '''Compute precision, recall, and Area Under Curve (AUC)
    Arguments:
    scores: np.array([], dtype=float)
    labels: np.array([], dtype=float)
    Returns:
    precisions: np.array([], dtype=float)
    recalls: np.array([], dtype=float)
    auc: float
    '''
    # Sort the thresolds in descent order
    score_index = np.argsort(scores)[::-1]
    scores = scores[score_index]
    labels = labels[score_index]
    # Remove duplicates scores
    thres_index = np.where(np.diff(scores))[0]
    thres_index = np.r_[thres_index, len(scores) - 1]
    tp = np.cumsum(labels)[thres_index]
    fp = thres_index - tp + 1
    precisions = tp / (tp+fp)
    recalls = tp / sum(labels)
    precisions = np.r_[1, precisions]
    recalls = np.r_[0, recalls]
    return precisions, recalls

def plot_auc(precision, recall, auc, img_name):
    plt.plot(recall, precision, color='b', linestyle='solid')
    plt.title('Precision-recall curve of lattice posterior')
    plt.ylabel('Precision')
    plt.xlabel('Recall')
    plt.xlim([0, 1.0])
    plt.ylim([0, 1.0])
    min_rec = np.arange(0, max(precision), .01)
    max_rec = np.arange(0, min(precision), .01)
    plt.plot([min(recall)] * len(min_rec), min_rec, linestyle='dotted', color='r')
    plt.plot([max(recall)] * len(max_rec), max_rec, linestyle='dotted', color='r')
    plt.text(.8, .9, f'AUC = {auc:.3f}', color='r')
    if min(recall < 1e-5):
        plt.text(min(recall), .06, f'{min(recall):.3f}', color='r')
    plt.text(max(recall)-.1, .06, f'{max(recall):.3f}', color='r')
    plt.savefig(img_name)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('results', type=str,help='Searching result file.')
    parser.add_argument('img_name', type=str, help='Output image filename.')
    args = parser.parse_args()

    labels, scores = read_search_results(result_fname=args.results)
    filt_labs, filt_scores = filter_score(labels, scores)
    precision, recall = compute_precision_recall(labels=filt_labs, scores=filt_scores)
    recall = recall * sum(filt_labs) / sum(labels)
    auc = np.abs(np.trapz(precision, recall))
    plot_auc(precision=precision, recall=recall, auc=auc, img_name=args.img_name)

if __name__ == main():
    main()
