#!/bin/bash

. path.sh

latdir=$1

for f in $latdir/*.gz;do
    fname=`basename f .gz`
    lattice-to-post --verbose=10 ark:"gunzip -c f|" ark:/dev/null > $latdir/:q

