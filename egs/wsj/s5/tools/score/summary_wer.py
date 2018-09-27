

'''
WER details summary for the whole dataset: Insertion, deletion, substitution
'''

import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('wer_detail_file')
    parser.add_argument('output_summary')
    args = parser.parse_args()

    sub = 0
    inser = 0
    delet = 0
    count = 0
    with open(args.wer_detail_file, 'r') as f:
        for i, j in enumerate(f.readlines()):
            if (i + 1) % 4 == 0:
                j = j.strip()
                line = j.split()
                sub += int(line[3])
                inser += int(line[4])
                delet += int(line[5])
                count += int(line[2]) + int(line[3]) + int(line[5])

    with open(args.output_summary, 'w') as o:
        o.write('Total symbols(character/word/phoneme): ' + str(count) + ' Substition: ' + str(sub) + ' Insertion: ' + str(inser) + ' Deletion: ' + str(delet) + '\n')

