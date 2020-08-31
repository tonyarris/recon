#!/usr/bin/bash

#enumerate all active subdomains for a given domain, and produce screenshots for all
RED='\033[0;31m'
NC='\033[0m'

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

echo -e  "${RED}Searching for subdomains with sublist3r...${NC}"
sublist3r.py -d $1 -o final.txt
sort -u final.txt

echo $1 >> final.txt

#TODO fix amass hang
#echo "${RED}Searching with amass enum...${NC}"
#amass enum -d $1 >> final.txt
#sort -u final.txt

echo -e "${RED}Now with subfinder...${NC}"
subfinder -d $1 >> final.txt
sort -u final.txt

sleep 5

echo -e "${RED}Now with github-search...${NC}"
github-subdomains.py -d $1 >> final.txt
sort -u final.txt

sleep 5

#grep to third level domains only
echo -e "${RED}Grepping to third level domains only...${NC}"
cat final.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >> $1_third_level.txt

sleep 5

echo -e "${RED}Gathering full third-level domains with Sublist3r...${NC}"
for domain in $(cat $1_third_level.txt); do sublist3r.py -d $domain -o $domain.txt; cat $domain.txt | sort -u >> $1_third_level.txt;done

sleep 5

echo -e "${RED}Probing for alive third-level domains...${NC}"
cat $1_third_level.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > probed.txt


sleep 5

sort -u probed.txt

sleep 5

echo -e "${RED}Scanning for open ports...${NC}"
nmap -iL probed.txt -T5 -oA scans/scanned.txt

sleep 5

echo -e "${RED}Running eyewitness${NC}"
eyewitness -f $pwd/probed.txt -d $1 --prepend-https
mv /usr/share/eyewitness/$1 eyewitness/$1

echo "n"

#TODO fix hang
#echo -e "${RED}Bruteforcing weak, common and default creds...${NC}"
#brutespray -f scans/scanned.txt.gnmap  -U /root/tools/SecLists/Usernames/top-usernames-shortlist.txt -P /root/tools/SecLists/Passwords/Common-Credentials/10k-most-common.txt --threads 5 --hosts 5 >> brutespray_output.txt
