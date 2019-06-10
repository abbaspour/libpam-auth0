FROM debian

ARG MODULE
ARG VERSION

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates openssh-server curl libnss-extrausers && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates

COPY pam /src/$MODULE-$VERSION/var/lib/auth0/
COPY auth0 /src/$MODULE-$VERSION/usr/share/pam-configs/
COPY auth0.conf /src/$MODULE-$VERSION/etc/
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
