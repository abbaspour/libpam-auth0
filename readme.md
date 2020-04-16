# PAM powered by Auth0
[![Build Status](https://travis-ci.org/abbaspour/libpam-auth0.svg?branch=master)](https://travis-ci.org/abbaspour/libpam-auth0)

### Steps

1. Clone
```bash
git clone git@github.com:abbaspour/libpam-auth0.git
```

2. Prepare `auth0.conf`

3. Prepare extrausers
You need `passwd` and `shadow` files in `extrausrs/` folder

Sample `passwd` file:

```text
t1@e.com:x:1005:100:null:/tmp:/bin/bash
```

Sample `shadow` file:
```text
t1@e.com:*:18052:0:99999:7:::
```

A good script to create shadow and passwd files from your Auth0 DB connection is: [mk-passwd.sh](https://raw.githubusercontent.com/abbaspour/auth0-bash/master/nss/mk-passwd.sh)

4. Build Server
```bash
make sshd
```

5. (Optional) SSH into server and tail logs
```bash
make bash
tail -F /var/log/auth0-pam.log
```

6. Prep `.env` file
This file has sample username and password. Sample `.env` file

```text
TEST_USER='t1@e.com'
TEST_PASS='t1@e.com'
```

7. Run ssh
```bash
make ssh
enter password 
```
