#!/bin/bash
#
# TODO
# - send log  to zabbix server on not 202
# - parse zabbix server conf for where to send alert
# - debug levels or is it overkill?
#   better to decide what output belongs to debug, logging, and monitoring
#
# Configuration files checked:
#    $HOME/.sendgrid_zabbix_alert.conf
#    /etc/zabbix/sendgrid_zabbix_alert.conf
# 
# the first one found is used see the example config for more information
# - https://github.com/mkgin/sendgrid_zabbix_alert
#
# By default alert scripts are here /usr/lib/zabbix/alertscripts
# Ideally this script is installed there and made readable and executable
# AlertScriptsPath can be set in zabbix_server.conf

if [ -f "$HOME/.sendgrid_zabbix_alert.conf" ];
then 
    source $HOME/.sendgrid_zabbix_alert.conf
    if [ $DEBUG ]; then echo "sourced configuration $HOME/.sendgrid_zabbix_alert.conf" ; fi
elif [ -f "/etc/zabbix/sendgrid_zabbix_alert.conf" ];
then
    source /etc/zabbix/sendgrid_zabbix_alert.conf
    if [ $DEBUG ]; then echo "sourced configuration /etc/zabbix/sendgrid_zabbix_alert.conf" ; fi
else
    echo "ERROR: Could not find or read configuration file"
fi

# tmp dir:  this may run as different users on the same machine
# curl wants to write to the directory that it is in if there is 
# a response
SCRIPTTMPDIR="${SCRIPTTMPDIR:-/tmp/sendgrid_zabbix_alert_$(whoami)}"

# create tmp dir if it doesn't exist ( but not with parents)
if [ ! -d $SCRIPTTMPDIR ];
then
    if  ! mkdir -p ${SCRIPTTMPDIR}  ;
    then
        echo "Could not create ${SCRIPTTMPDIR}"
        exit 1
    fi
fi 

cd "${SCRIPTTMPDIR}"
# could check that we made it to the right dir

# set default URL if not set
CURL_URL="${CURL_URL:-https://api.sendgrid.com/v3/mail/send}"

# current unix time
EPOCHDATE=$(date +%s)

if [ $TESTPARAMSINCONF ];
then
    echo "TESTPARAMSINCONF: is True"
    echo "Not using input arguments. Assuming that"
    echo "Using MAILTO, MAILSUBJECT and MAILBODY as set in configuration"
else
# Zabbix sets the following parameters when calling the alertscript
    if [ $DEBUG ]; then echo "DEBUG: Using argument parameters for MAILTO, MAILSUBJECT and MAILBODY" ; fi 
    MAILTO=$1
    MAILSUBJECT=$2

# To keep JSON happy, strip the following:
# - Carriage returns and (0x0d) use \n instead
# - " and use \\\" 
# 
# linefeeds 0x0a, commas and semicolons are not handled yet ( but may need handling)
    MAILBODY=$( echo "$3" |sed  's/\x0d/\\n/g' | sed 's/\"/\\\"/g' | tr -d "\n" )
fi 

# your API keys will show up in in the debug info if "--curl-trace" is used 
if [ $DEBUG ]
then 
# debug lowest level
# good to know environment sending the script
    echo "$(env)" > ${SCRIPTTMPDIR}/env_"$EPOCHDATE"
    echo "$MAILBODY" > ${SCRIPTTMPDIR}/MAILBODY_"$EPOCHDATE"
    # Curl args when debugging
    CURL_ARGS="--write-out %{http_code} --show-error --silent --dump-header ${SCRIPTTMPDIR}/recieved_headers_${EPOCHDATE}"
else
    # Curl args when not debugging
    CURL_ARGS="--write-out %{http_code} --silent"
fi

# This file is written to /tmp if the API returns anything other than headers.
# the result is needed for monitoring and logging
CURL_OUTPUT_FILENAME="http_response_${EPOCHDATE}"
# maybe we can add the DIR.. but we should be there already ${SCRIPTTMPDIR}

if [ $DEBUG ]; then echo "DEBUG: CURL_URL=$CURL_URL" ; fi

CURL_DATA=$( cat <<EOF
{"personalizations": [{"to": [{"email": "${MAILTO}"}]}],
"from": {"email": "${MAILFROMADDR}"},
"subject": "'${MAILSUBJECT}'",
"content": [{"type": "text/plain","value": "${MAILBODY}"}],
"tracking_settings": {
"click_tracking": { "enable": false},
"open_tracking": { "enable": false}
} }
EOF
)

if [ $DEBUG ];
then 
    echo "DEBUG: CURL_OUTPUT_FILENAME=${CURL_OUTPUT_FILENAME}" 
    echo "DEBUG: SCRIPTTMPDIR=${SCRIPTTMPDIR}"
    echo "DEBUG: CURL_ARGS=${CURL_ARGS}"
    echo "DEBUG: CURL_DATA=${CURL_DATA}"
fi
if [ $EXIT_BEFORE_CURL ];
then
    echo "EXIT_BEFORE_CURL is set, exiting now!!"
    exit 1;
fi

#run curl ( could have this in a variable two as it contains the response code
CURL_OUTPUT=$(curl $CURL_ARGS --request POST \
  --url $CURL_URL \
  --header 'Authorization: Bearer '$SENDGRID_API_KEY'' \
  --header 'Content-Type: application/json' \
  --data "'${CURL_DATA}'" \
  --output $CURL_OUTPUT_FILENAME)

CURL_EXIT_CODE=$?

if [ $DEBUG ];
then 
    echo "DEBUG: CURL_EXIT_CODE=$CURL_EXIT_CODE"
    echo "DEBUG: CURL_OUTPUT begin ****"
    echo "${CURL_OUTPUT}"
    echo "**** DEBUG: CURL_OUTPUT end"
fi
# get zabbix_sender related info
# check exit code
if [ ! $CURL_EXIT_CODE ];
then
    echo "ERROR: curl error exit code $CURL_EXIT_CODE"
    # send this somewhere if possible
elif [ $DEBUG ]; 
then
    echo "DEBUG: returned exit code $CURL_EXIT_CODE"
fi

# We still need to check for 202 status code and return error otherwise.
#maybe we want to check that it is a number
if [ "$CURL_OUTPUT" -eq "202" ];
then 
    echo "DEBUG: sendgrid http status 202. Success!"
else 
    echo "ERROR: sendgrid http status: $CURL_OUTPUT"
fi
# 
if [ $DEBUG ] && [ -f $CURL_OUTPUT_FILENAME ] ; 
then
    echo "DEBUG: sendgrid http response at $SCRIPTTMPDIR/$CURL_OUTPUT_FILENAME"
fi

if [ -f $CURL_OUTPUT_FILENAME ];
then
    echo "ERROR: Sendgrid error begin ****"
    cat $CURL_OUTPUT_FILENAME
    echo
    echo "**** Sendgrid error end"
    # send contents 
fi


exit
