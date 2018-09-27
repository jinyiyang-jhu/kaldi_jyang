#!/bin/bash

iflile=$1
ofile=$2


python3 tools/score/wer_details_to_wer.py $iflile $ofile

