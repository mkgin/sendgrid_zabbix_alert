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
MAILBODY=$3

#curl --trace-ascii curltrace --request POST \
#curl --request POST \
curl --write-out %{http_code} --trace-ascii curltrace --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header 'Authorization: Bearer '$SENDGRID_API_KEY'' \
  --header 'Content-Type: application/json' \
  --data '{"personalizations": [{"to": [{"email": "'"$MAILTO"'"}]}], \
"from": {"email": "'"$MAILFROMADDR"'"}, \
"subject": "'"$MAILSUBJECT"'", \
"content": [{"type": "text/plain","value": "'"$MAILBODY"'"}], \
"tracking_settings": { \
"click_tracking": { "enable": false}, \
"open_tracking": { "enable": false} \
} \
}'
