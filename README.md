Sendgrid Zabbix Alert
=====================
Work in progress, basically an alertscript called by Zabbix server
that uses sendgrid to send a message

Requirements:
-------------

### Software
* curl
* zabbix server
* bash

### Configuration file

Configuration is sourced from  /etc/zabbix/sendgrid_zabbix_alert.conf
to set MAILFROMADDR, MAILFROMNAME and SENDGRID_API_KEY. See 
sendgrid_zabbix_alert.conf.example for more information

### Zabbix configuration

Normally alert scripts are here /usr/lib/zabbix/alertscripts
AlertScriptsPath can be set to a location for custom alert scripts
in zabbix_server.conf

Check the Zabbix documentions for Custom alert scripts.

When calling the alertscript, Zabbix sets the following parameters 
MAILTO=$1
MAILSUBJECT=$2
MAILBODY=$3

Parameters can be customized. (See custom alert scripts)

### Installation

Assuming default settings:

Set variables in 
/etc/zabbix/sendgrid_zabbix_alert.conf

Copy sendgrid_zabbix_alert.sh to /usr/lib/zabbix/alertscripts

There is also a file to help debug your alert parameters
test_zabbix_alert.sh
