#!/usr/local/bin/expect -d -f

set username [lrange $argv 0 0]
set password [lrange $argv 1 1]

spawn bash --noprofile --norc
send "export PAM_TYPE=auth\n"
send "export PAM_USER=${username}\n"
send "export CONFIG_FILE=auth0.conf.amin01\n"
send "export LOG_FILE=auth0.log\n"
send "./pam.js\n"
send "$password\n"

interact timeout 1 return
