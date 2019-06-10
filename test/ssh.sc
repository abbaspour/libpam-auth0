#!/usr/local/bin/expect -d -f

set username [lrange $argv 0 0]
set password [lrange $argv 1 1]
set server "localhost"
set port 2222

spawn ssh -q -o PreferredAuthentications=keyboard-interactive \
	    -o PubkeyAuthentication=no  \
	    -o StrictHostKeyChecking=no \
	    -o UserKnownHostsFile=/dev/null \
	    -p $port $username@$server

match_max 100000
expect "Password:"
send $password
send \n
expect "\$ $"
send "uname -a\n"
expect "\$ $"
send "id\n"
expect "uid=*($username) gid=100(users) groups=100(users)"
interact timeout 1 return
#expect "$username@*:~\$ "
#exit
