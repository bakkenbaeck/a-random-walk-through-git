#!/bin/bash

OUTPUTHTML=1 ./DEMO.sh 1000 > body.html 2>&1
head --l 2 body.html > output.html
cat contents.html >> output.html
tail -n +3 body.html >> output.html
rm -f contents.html body.html
sed -i 's/<ijon/\&lt;ijon/' output.html
SPWD=$(pwd | sed 's_/_\\/_g')\\/
sed -i "s/$SPWD//" output.html
cp output.html docs/index.html
