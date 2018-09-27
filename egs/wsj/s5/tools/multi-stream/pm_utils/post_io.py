#!/usr/bin/python
import numpy as np
import sys
import os


epsilon = 10 ** (-10)
def readKaldiPost(postFile, numPhones):
    uttDict = dict()
    with open(postFile,'r') as P:
        PList=P.readlines()
        for PLine in PList:
            PLine = PLine.replace("]","")
            PRowList = PLine.split("[")
            uttid = PRowList.pop(0)
            for postPerFrameStr in PRowList:
                postPerFrameList = postPerFrameStr.split()
                if not len( postPerFrameList ) == numPhones:
                       print ('Frame Invalid number of phones: ' \
                               + str(len( postPerFrameList))+ '\n')
                       print ('Frame is:\n')
                       print (postPerFrameStr + '\n')
                       print ('Input number of phones is: ' + str(numPhones) + '\n')
                       sys.exit(1)
                else:
                        postPerFrameList = [element_compare_epsilon(float(x),epsilon) for x in postPerFrameList]
                        postPerFrameArray = np.asarray(postPerFrameList)
                if uttid in uttDict.keys():
                   uttDict[uttid]= np.concatenate((uttDict[uttid],[postPerFrameArray]))
                else:
                   uttDict[uttid]= np.array([postPerFrameArray])
    return uttDict


def element_compare_epsilon(element,epsilon):
    if abs(element) < epsilon:
        element = epsilon
    return element




