#!/bin/bash

## Basic constants and configurations
BASEURL="https://www.googleapis.com/pagespeedonline/v2/runPagespeed"
APIKEY=$(cat apiKey.txt)
filter_third_party_resources=true
locale="ja_JP"
timezone="Asia/Tokyo"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd `dirname ${0}`

STRATEGIES=(desktop mobile)
URLS=$(cat urllist.txt)

RESULTDIR="results/$(TZ=$timezone date +%y%m%d_%H)"
if [ -e $RESULTDIR ]; then
    echo "Warning: Result already exists (${RESULTDIR}) (skipping)"
else
    mkdir $RESULTDIR
    echo "Inspecting..."
    for strategy in ${STRATEGIES[@]}; do
        echo "Strategy: $strategy"
        mkdir $RESULTDIR/$strategy
        for url in ${URLS[@]}; do
            echo "${url}..."
            urlfile=$(echo $url | sed 's/https:\/\///' | sed 's/\//_/g')
            curl -s -X GET "${BASEURL}?url=${url}&locale=${locale}&strategy=${strategy}&key=${APIKEY}" \
                > $RESULTDIR/$strategy/${urlfile}.json
        done
    done
    echo "Done!"
fi
echo

echo "## Summary ##"
for strategy in ${STRATEGIES[@]}; do
    echo
    echo "Strategy: $strategy"
    jsons=$(find $RESULTDIR/$strategy -type f)
    for json in ${jsons[@]}; do
        url=$(cat ${json} | jq .id)
        score=$(cat ${json} | jq .ruleGroups.SPEED.score)
        if [ $score -gt 85 ]; then
            score=$GREEN$score$NC
        elif [ $score -gt 60 ]; then
            score=$YELLOW$score$NC
        else
            score=$RED$score$NC
        fi
        echo -e "$url\t$score"
    done
done

