#! /bin/bash
#Thank you to nathan for being my regex hero
cd results
for hhvm in hhvmclean- hhvmbump- hhvmbumpnocount- 
do
	echo $hhvm
	grep -o "^Requests per.* " *.log | grep "$hhvm" | sed -E 's/.*n([[:digit:]]+)-c([[:digit:]]+)[^0-9]+([[:digit:]]+\.[[:digit:]]+).*/\1,\2,\3/' > $hhvm'requestspersecond.csv'
        grep -o "^Time taken.* " *.log | grep "$hhvm" | sed -E 's/.*n([[:digit:]]+)-c([[:digit:]]+)[^0-9]+([[:digit:]]+\.[[:digit:]]+).*/\1,\2,\3/' > $hhvm'totaltime.csv'
done
