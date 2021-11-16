# Python 3

from genericpath import exists
import os
import glob
import sys

def write_wav_scp(wavlist, absdir, ofname):
    with open(ofname, 'w') as ofhd:
        for f in wavlist:
            print(os.path.basename(f).split('.')[0], os.path.join(absdir, f),file=ofhd)

def read_text(textfile):
    count = 0
    textlist = []
    with open(textfile, 'r') as ifhd:
        for line in ifhd:
            if count != 0:
                tokens = line.strip().split('\t')
                uttid = tokens[1].split('.')[0]
                spkid = tokens[2]
                prompt = tokens[3]
                trans = tokens[4]
                textlist.append([uttid, spkid, prompt, trans])
            count += 1
    return textlist

def write_text_prompt(textlist, ofname):
    with open(ofname, 'w') as ofhd:
        for lst in textlist:
            print(lst[0], lst[2], file=ofhd)

def write_text_trans(textlist, ofname):
    with open(ofname, 'w') as ofhd:
        for lst in textlist:
            print(lst[0], lst[3], file=ofhd)

def write_utt2spk(textlist, ofname):
    with open(ofname, 'w') as ofhd:
        for lst in textlist:
            print(lst[0], lst[1], file=ofhd)

def write_spk2utt(textlist, ofname):
    with open(ofname, 'w') as ofhd:
        for lst in textlist:
            print(lst[1], lst[0], file=ofhd)


if __name__ == "__main__":
    absdir = "/export/b07/jyang/kaldi-jyang/kaldi/egs/gale_tdt_mandarin/s5"
    wavs = "Guangzhou_Cantonese_Scripted_Speech_Corpus_Daily_Use_Sentence/WAV/**/*.wav"
    textfile = "Guangzhou_Cantonese_Scripted_Speech_Corpus_Daily_Use_Sentence/UTTRANSINFO.txt"
    datadir = "data/Guangzhou_Cantonese_Scripted_Speech"


    wavlist = glob.glob(wavs, recursive=True)
    if not os.path.exists(datadir):
        os.mkdir(datadir)
    
    write_wav_scp(wavlist, absdir, os.path.join(datadir, 'wav.scp'))
    textlist = read_text(textfile)
    write_text_prompt(textlist, os.path.join(datadir, 'text.man'))
    write_text_trans(textlist, os.path.join(datadir, 'text.can'))
    write_utt2spk(textlist, os.path.join(datadir, 'utt2spk'))
    write_spk2utt(textlist, os.path.join(datadir, 'spk2utt'))