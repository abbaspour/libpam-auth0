MODULE := libpam-auth0
VERSION := 0.1.0

DEB_FILE := ${MODULE}-${VERSION}.deb

include .env

clean:
	rm -f deb/${DEB_FILE}

%.deb:
	docker build \
	    --build-arg MODULE=${MODULE} \
	    --build-arg VERSION=${VERSION} \
	    --tag ${MODULE}:${VERSION} . -f docker/debian.Dockerfile
	docker run -it -v `pwd`/deb:/deb ${MODULE}:${VERSION} cp ${DEB_FILE} /deb/

sshd: deb/${DEB_FILE}
	docker run -p 2222:22 -it ${MODULE}:${VERSION} /usr/sbin/sshd -D -e

stop:
	docker kill `docker ps | awk '/${MODULE}:${VERSION}/{print $$1}'`

bash: deb/${MODULE}-${VERSION}.deb
	docker exec -it `docker ps | awk '/${MODULE}:${VERSION}/{print $$1}'` bash

log: deb/${MODULE}-${VERSION}.deb
	docker exec -it `docker ps | awk '/${MODULE}:${VERSION}/{print $$1}'` tail -F /var/log/auth0-pam.log

ssh: deb/${MODULE}-${VERSION}.deb
	ssh -o PreferredAuthentications=keyboard-interactive \
	    -o PubkeyAuthentication=no  \
	    -o StrictHostKeyChecking=no \
	    -o UserKnownHostsFile=/dev/null \
	    -p 2222 '${TEST_USER}'@localhost

test:
	expect ./test/ssh.sc ${TEST_USER} ${TEST_PASS}

local:
	expect ./test/invoke.sc ${TEST_USER} ${TEST_PASS}

.PHONY: test local stop clean


