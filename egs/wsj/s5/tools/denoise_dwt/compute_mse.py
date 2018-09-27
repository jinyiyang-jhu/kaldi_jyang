#!/home/jynag/anaconda3/bin/python3.6
import numpy as np
from scipy.io import wavfile
import argparse
import subprocess
import io
import sys

def read_scp(flist):
    '''return: fDict[uttid]-> {[frate, faudio]}
    '''
    fDict = {}
    for f in flist:
        fL = f.split()
        uttid = fL.pop(0)
        if '|' in fL:
            output = subprocess.check_output(' '.join(fL)[:-1], shell=True)
            audio = io.BytesIO(output)
            fRate, faudio = wavfile.read(audio)
        else:
            fRate, faudio = wavfile.read(fL[-1])
        fDict[uttid] = [fRate, faudio]
    return fDict


def compute_mse(oriDict, estDict):
    mse = []
    for i in oriDict.keys():
        oriList = oriDict[i]
        estiList = estDict[i]
        if oriList[0] != estiList[0]:
            sys.exit('Sample rate not equal')
        ori = oriList[1]
        esti = estiList[1]
        if len(ori) >= len(esti):
            wavlen = len(esti)
        else:
            wavlen = len(ori)
        err = np.zeros(wavlen)
        ori_seg = ori[:wavlen]
        esti_seg = esti[:wavlen]
        err = ori_seg - esti_seg
       # for i in range(wavlen):
       #     err[i] = ori_seg[i] - esti_seg[i]
        serr = np.square(err)
        mse.append( 1 / wavlen * np.sum(serr))
    return sum(mse) / len(mse)


def main():
    parser = argparse.ArgumentParser(description='Compute mse')
    parser.add_argument('--cleanscp', help='format: utt1 wavname',required=True)
    parser.add_argument('--denoisescp',required=True)
    args = parser.parse_args()
    with open(args.cleanscp, 'r') as c:
        cList = c.readlines()
    with open(args.denoisescp, 'r') as d:
        dList = d.readlines()

    cDict = read_scp(cList)
    dDict = read_scp(dList)

    print('MSE is ' + str(compute_mse(cDict, dDict)))

if __name__ == '__main__':
    main()
else:
    raise ImportError('This script cannot be imported')
