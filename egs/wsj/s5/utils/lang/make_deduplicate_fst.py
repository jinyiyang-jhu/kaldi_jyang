#!/usr/bin/env python3

import argparse
import sys
import re
import io

sys.stdout = open(1, 'w', encoding='latin-1', closefd=False)
sys.stderr = open(2, 'w', encoding='latin-1', closefd=False)

def get_args():
    parser = argparse.ArgumentParser(description='''This script creates the
    text form of a FST used for deduplicate oov. This FST will be compiled by
    fstcompile using the appropriate symbol table (words.txt). The output goes
    to stdout. Read from stdin, which should be list of words, e.g.,
    words.txt. Note that words.txt should not contain any disambig symbols, oov
    symbols, or anything that is not in
    lexicon.''')
    parser.add_argument('--oov-sym', dest='oov_sym', type=str,
                        help='''Text form of OOV symbol, e.g., <oov>.''')
    args = parser.parse_args()
    return args

def read_word_list(oov_sym):
    """Read the word list, with lines like 'word id ...'.
    Returns a list of words, where 'word' is a string.
    """
    words = []
    input_stream = io.TextIOWrapper(sys.stdin.buffer, encoding='latin-1')
    #with open(filename, 'r', encoding='latin-1') as f:
    whitespace = re.compile('[ \t]+')
    for line in input_stream:
        tokens = whitespace.split(line.strip())
        if len(tokens) != 2:
            print("{0}: error: found bad line '{1}' in word list file {2}".format(
            sys.argv[0], line.strip(), filename), file=sys.stderr)
            sys.exit(1)
        word = tokens[0]
        if word != "<eps>" and word != oov_sym:
            words.append(word)
    if len(words) == 0:
        print("{0}: error: found no words in word list file {1}".format(
            sys.argv[0], filename), file=sys.stderr)
        sys.exit(1)
    return words

def write_fst(words, oov_sym):
    """Write the text format of O.fst to the standard output.
    'words' is a list of words (type is str)
    """
    loop_state = 0
    oov_state = 1
    final_state = 2
    next_state = 3

    print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
            src=loop_state,
            dest=oov_state,
            isym=oov_sym,
            osym="<eps>",
            cost=0.0))
    print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
            src=oov_state,
            dest=oov_state,
            isym=oov_sym,
            osym="<eps>",
            cost=0.0))
    print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
            src=oov_state,
            dest=final_state,
            isym="<eps>",
            osym=oov_sym,
            cost=0.0))
    for word in words:
        print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
                src=loop_state,
                dest=loop_state,
                isym=word,
                osym=word,
                cost=0.0))
        print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
                src=oov_state,
                dest=next_state,
                isym=word,
                osym=oov_sym,
                cost=0.0))
        print("{src}\t{dest}\t{isym}\t{osym}\t{cost}".format(
                src=next_state,
                dest=loop_state,
                isym="<eps>",
                osym=word,
                cost=0.0))
        next_state += 1
    print("{state}\t{cost}".format(
        state=loop_state,
        cost=0.0))
    print("{state}\t{cost}".format(
        state=final_state,
        cost=0.0))

def main():
    args = get_args()
    word_list = read_word_list(args.oov_sym)
    oov_sym = args.oov_sym
    write_fst(words=word_list, oov_sym=oov_sym)

if __name__ == '__main__':
    main()
