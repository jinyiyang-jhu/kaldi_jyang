import numpy as np
import sys
import re

def main():
    i_file = sys.argv[1]
    o_file = sys.argv[2]
    merge_NSN = sys.argv[3] # "merge or not_merge"

    flag1 = None
    flag2 = None
    with open(o_file, 'w') as O:
        with open(i_file, 'r') as p:
            p_list = p.readlines()
            for p_line in p_list:
                flag1 = re.search('\[', p_line)
                flag2 = re.search('\]', p_line)
                if flag1 is None:
                    p_line = p_line.rstrip('\n')
                    if merge_NSN == "merge":
                        p_split = p_line.split()
                        p_split[0] = float(p_split[0]) + float(p_split[2])
                        del p_split[2]
                        p_line = ' '.join([str(i) for i in p_split])
                    if  flag2 is None:
                         O.write(' [ ' + p_line + ' ]')
                    else:
                         O.write(' [ ' + p_line + '\n')
                else:
                    utt = p_line.split()[0]
                    O.write(utt)
                    print ('Writing utt')


if __name__ == '__main__':
    main()
else:
    raise ImportError('Can not be imported')
