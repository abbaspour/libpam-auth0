MODULE := libpam-auth0
VERSION := 0.2.0

RELEASE_FOLDER := release
DEB_FILE := ${MODULE}-${VERSION}.deb
RELEASE_FILE := ${RELEASE_FOLDER}/${DEB_FILE}

include .env

%.deb:
	mkdir -p ${RELEASE_FOLDER}
	docker ps || { echo 'Docker is not running'; exit 2; }
	docker build \
	    --build-arg MODULE=${MODULE} \
	    --build-arg VERSION=${VERSION} \
	    --tag ${MODULE}:${VERSION} . -f docker/debian.Dockerfile
	docker run -it -v `pwd`/${RELEASE_FOLDER}:/release ${MODULE}:${VERSION} cp ${DEB_FILE} /release/

clean:
	rm -f ${RELEASE_FILE}

sshd: release/${DEB_FILE}
	docker ps | grep "${MODULE}:${VERSION}" || docker run -p 2222:22 -d -it ${MODULE}:${VERSION} /usr/sbin/sshd -D -e

stop:
	#docker cp `docker ps | awk '/${MODULE}:${VERSION}/{print $$1}'`:/var/log/auth0-pam.log . && cat auth0-pam.log
	docker kill `docker ps -f "ancestor=${MODULE}:${VERSION}" --format "{{.ID}}"`

bash: sshd
	docker exec -it `docker ps -f "ancestor=${MODULE}:${VERSION}" --format "{{.ID}}"` bash

log: sshd
	docker exec -it `docker ps -f "ancestor=${MODULE}:${VERSION}" --format "{{.ID}}"` touch /var/log/auth0-pam.log
	docker exec -it `docker ps -f "ancestor=${MODULE}:${VERSION}" --format "{{.ID}}"` tail -F /var/log/auth0-pam.log

ssh: sshd
	ssh -o PreferredAuthentications=keyboard-interactive \
	    -o PubkeyAuthentication=no  \
	    -o StrictHostKeyChecking=no \
	    -o UserKnownHostsFile=/dev/null \
	    -p 2222 '${TEST_USER}'@localhost

test: sshd
	expect ./test/ssh.sc ${TEST_USER} ${TEST_PASS}

local:
	expect ./test/invoke.sc ${TEST_USER} ${TEST_PASS}

release: ${RELEASE_FILE}
	curl -T ${RELEASE_FILE} \
		-u${BINTRAY_USER}:${BINTRAY_API_KEY} \
		'https://api.bintray.com/content/amin/libpam-auth0/${MODULE}/${VERSION}/${DEB_FILE};deb_distribution=wheezy;deb_component=main;deb_architecture=amd64'

.PHONY: clean


