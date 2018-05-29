Sendgrid Zabbix Alert
=====================
Evolving work in progress,  

Alertscript called by Zabbix server that uses the Sendgrid API to send a message

Check for errors, can log debug information, sending failure information back to zabbix to be implemented next.

Requirements:
-------------

### Software

* curl
* zabbix_server 
* bash
* zabbix_sender ( to report errors )

### Sendgrid API key

* https://sendgrid.com/

### Configuration file

The configuration is sourced from `$HOME/.sendgrid_zabbix_alert.conf`
or `/etc/zabbix/sendgrid_zabbix_alert.conf` to set MAILFROMADDR,
MAILFROMNAME and SENDGRID_API_KEY. See `sendgrid_zabbix_alert.conf.example`
for more information. It is also possible to set these values in the configuration 
file for testing.

### Zabbix configuration

Normally alert scripts are here /usr/lib/zabbix/alertscripts
`AlertScriptsPath` can be set to a location for custom alert scripts
in `zabbix_server.conf`

The script need to be installed and have permissions set so that Zabbix is able to execute it.

Check the Zabbix documention for Custom alert scripts.

When calling the alertscript, Zabbix sets the following parameters 
```
MAILTO=$1
MAILSUBJECT=$2
MAILBODY=$3
```

Parameters can be customized. (See custom alert scripts)

### Installation

Assuming default settings:

Set variables in 
`/etc/zabbix/sendgrid_zabbix_alert.conf`

Copy `sendgrid_zabbix_alert.sh` to `/usr/lib/zabbix/alertscripts`

There is also a short script that will help see what zabbix is sending.

`test_zabbix_alert.sh`
