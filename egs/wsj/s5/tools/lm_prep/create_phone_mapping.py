
'''Create a phone root to dependant phone mapping'''

import argparse

def read_root(fid):
    dict_map = {}
    with open(fid, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            if len(tokens) == 6:
                root = tokens[2].split('_')[0]
            else:
                root = tokens[2]
            for i in tokens[2:]:
                dict_map[i] = root
    return dict_map

def read_phones(fid):
    dict_phones = {}
    with open(fid, 'r') as f:
        for line in f:
            tokens = line.strip().split()
            if ('eps' not in tokens[0]) and ('#' not in tokens[0]):
                dict_phones[tokens[0]] = tokens[1]
    return dict_phones

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('root', help='data/lang/phones/root.txt')
    parser.add_argument('phones', help='data/lang/phones.txt')
    parser.add_argument('output', help='outputfile')
    args = parser.parse_args()

    root = read_root(args.root)
    phone_map = read_phones(args.phones)

    dict_root = {}
    with open(args.output, 'w') as f:
        for i in phone_map.keys():
            phone_id = phone_map[i]
            print(phone_id, root[i], file=f)

if __name__ == '__main__':
    main()


