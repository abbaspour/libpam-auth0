FROM debian

ARG MODULE
ARG VERSION

ENV DEBIAN_FRONTEND noninteractive

    #apt-get -y clean && \
    #rm -rf /var/lib/apt/lists/* && \
    #apt-get install -y --no-install-recommends nodejs && \

RUN apt-get update && \
    apt-get install -y  --no-install-recommends wget gnupg2 apt-transport-https ca-certificates openssh-server libnss-extrausers apt-utils && \
    sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && \
    sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -'

COPY pam.dart /tmp

RUN apt-get update && \
    apt-get install -y dart && \
    mkdir -p /src/$MODULE-$VERSION/var/lib/auth0 && \
    /usr/lib/dart/bin/dart2native /tmp/pam.dart -o /src/$MODULE-$VERSION/var/lib/auth0/pam

#COPY pam.js /src/$MODULE-$VERSION/var/lib/auth0/pam
COPY auth0 /src/$MODULE-$VERSION/usr/share/pam-configs/
COPY auth0.conf /src/$MODULE-$VERSION/etc/auth0.conf
COPY debian /src/$MODULE-$VERSION/DEBIAN

RUN cd /src && dpkg -b $MODULE-$VERSION && dpkg -i $MODULE-$VERSION.deb

## NSS
COPY extrausers /var/lib/extrausers/
RUN sed -i -e '/^passwd: / s/$/  extrausers/;/^group: / s/$/  extrausers/;/^shadow: / s/$/  extrausers/;' /etc/nsswitch.conf

## PAM
RUN pam-auth-update --package

## SSHd
RUN mkdir -p /run/sshd
RUN sed -i -e 's|ChallengeResponseAuthentication no|ChallengeResponseAuthentication yes|g' /etc/ssh/sshd_config
#RUN sed -i -e 's|#LogLevel INFO|LogLevel DEBUG3|g' /etc/ssh/sshd_config

EXPOSE 22
WORKDIR /src
