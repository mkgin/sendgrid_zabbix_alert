#!/bin/bash
#
# append date and parameters to LOGFILE
# LOGFILE must by writeable but the user running the script

LOGFILE="/tmp/test_zabbix_alert.log"
PAR_COUNT=1

echo "$(date --rfc-3339=sec) Received $# parameters" >> $LOGFILE
for PARAMETER in "$@"
do
    echo "Parameter# $PAR_COUNT: $PARAMETER" >> $LOGFILE
    (( PAR_COUNT++ ))
done
