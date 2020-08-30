#!/usr/bin/bash

#enumerate all active subdomains for a given domain, and produce screenshots for all
if [ ! -d $1 ]; then
	mkdir $1
fi

cd $1

if [ ! -d "thirdlevels" ]; then 
	mkdir thirdlevels
fi

if [ ! -d "scans" ]; then
	mkdir scans
fi

if [ ! -d "eyewitness" ]; then
	mkdir eyewitness
fi

pwd=$(pwd)

echo "Searching for subdomains with sublist3r"
sublist3r.py -d $1 -o final.txt
sort -u final.txt

echo $1 >> final.txt

#grep to third level domains only
echo "Grepping to third level domains only"
cat final.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >> $1_third_level.txt

echo "Gathering full third-level domains with Sublist3r..."
for domain in $(cat $1_third_level.txt); do sublist3r.py -d $domain -o $domain.txt; cat $domain.txt | sort -u >> final.txt; done 

echo "Probing for alive third-level domains"
cat final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > probed.txt

echo "Scanning for open ports"
nmap -iL probed.txt -T5 -oA scans/scanned.txt

echo "Running eyewitness"
eyewitness -f $pwd/probed.txt -d $1 --prepend-https
mv /usr/share/eyewitness/$1 eyewitness/$1
