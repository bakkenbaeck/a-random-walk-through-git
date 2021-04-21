#!/bin/bash

OUTPUTHTML=1 ./DEMO.sh 1000 > body.html 2>&1
head --l 2 body.html > output.html
cat contents.html >> output.html
tail -n +3 body.html >> output.html
rm -f contents.html body.html
sed -i 's/<ijon/\&lt;ijon/' output.html
