
import sys

ifile = sys.argv[1]
ofile = sys.argv[2]

with open(ifile, encoding='utf-8') as f:
    details = f.readlines()

dict_wer = {}
for i, j in enumerate(details):
    if (i+1) % 4 == 0:
        j = j.strip()
        line = j.split()
        uttid = line.pop(0)
        line.pop(0)
        errs = [int(i) for i in line]
        dict_wer[uttid] = format(((sum(errs) - errs[0]) / (errs[0] + errs[1] + errs[3])), '.2f')

with open(ofile, 'w') as f:
    for k in sorted(dict_wer.keys()):
        f.write(k + ' ' + dict_wer[k] + '\n')

