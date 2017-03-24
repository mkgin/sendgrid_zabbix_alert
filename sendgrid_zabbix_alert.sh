#!/bin/bash
#

# define the following in settings in this 
source /etc/zabbix/sendgrid_zabbix_alert.conf
#MAILFROMADDR=
#MAILFROMNAME=
#SENDGRID_API_KEY=

# By default alert scripts are here /usr/lib/zabbix/alertscripts
# AlertScriptsPath can be set in zabbix_server.conf


# Zabbix sets the following parameters when calling the alertscript
MAILTO=$1
MAILSUBJECT=$2
# Strip Carriage returns and linefeeds and use \n instead\n
MAILBODY=$( echo "$3" |sed  's/\x0d/\\n/g' | tr -d "\n" )
# Some extra curl args
CURL_ARGS="--write-out %{http_code} --silent"
DEBUG=0
# debugging to write output to /tmp ... your API keys will show up in
# in the debug info...

if [ $DEBUG ]
then 
echo "$(env)" > /tmp/sendgrid_zabbix_alert_env_$(date +%s)
echo "$MAILBODY" > /tmp/sendgrid_zabbix_alert_MAILBODY_$(date +%s)
CURL_ARGS="--write-out %{http_code} --trace-ascii /tmp/sendgrid_zabbix_alert_curltrace_$(date +%s)"
fi


CURL_URL="https://api.sendgrid.com/v3/mail/send"
CURLDATA=$( cat <<EOF
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

curl --request POST \
  --url $CURL_URL \
  --header 'Authorization: Bearer '$SENDGRID_API_KEY'' \
  --header 'Content-Type: application/json' \
  --data "'${CURLDATA}'" \
  $CURL_ARGS

echo "\nCURL EXIT $?"

# We still need to check for 202 and return error otherwise.
exit
