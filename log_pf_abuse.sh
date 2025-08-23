#!/bin/sh
# log_pf_abuse.sh – zapisuje listę IP z tabeli <abuse> do pliku z datą

LOGFILE="/var/log/pf_abuse.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "==== $DATE ====" >> $LOGFILE
doas pfctl -t abuse -T show >> $LOGFILE 2>&1
echo "" >> $LOGFILE
