#new
FROM alpine:3.12

LABEL maintainer="Loïc Plaire <loic.plaire@optelo.com>"

## Installation des dépendances
RUN apk add --update --no-cache \
    build-base \
    autoconf \
    automake \
    libtool \
    libxml2-dev \
    mariadb-dev \
    bison \
    libssh-dev \
    libressl-dev \
    subversion

RUN cp /usr/include/poll.h /usr/include/sys/poll.h
RUN cp /usr/include/unistd.h /usr/include/sys/unistd.h

RUN mkdir -p /kannel/sources-kannel
WORKDIR /kannel/sources-kannel

# Récupération des sources Kannel (dont sqlbox)
RUN svn co https://svn.kannel.org/gateway/trunk  --trust-server-cert

# BUILD KANNEL
WORKDIR /kannel/sources-kannel/trunk

RUN ./bootstrap.sh
RUN ./configure --with-mysql --with-mysql-dir=/var/lib/mysql --enable-start-stop-daemon
RUN make
RUN make bindir=/usr/local/kannel install
# => Une fois cette étape passée, les bearerbox et smsbox sont présentes dans /usr/local/sbin

# BUILD SQLBOX
WORKDIR /kannel/sources-kannel/trunk/addons/sqlbox

RUN ./configure  --with-kannel-dir=/usr/local/kannel
RUN make
RUN make install
# => Une fois cette étape passée, la sqlbox est présente dans /usr/local/sbin

# CONFIG PART I
RUN mkdir /kannel/conf-kannel /kannel/store /kannel/logs

COPY kannel.conf /kannel/conf-kannel/
COPY sqlbox.conf /kannel/conf-kannel/

ARG KANNEL_DATABASE
ARG KANNEL_USER
ARG KANNEL_PASSWORD

RUN sed -i "s/kannel_database/$KANNEL_DATABASE/g" /kannel/conf-kannel/*.conf
RUN sed -i "s/kannel_user/$KANNEL_USER/g" /kannel/conf-kannel/*.conf
RUN sed -i "s/kannel_password/$KANNEL_PASSWORD/g" /kannel/conf-kannel/*.conf

RUN chmod 777 /kannel/store /kannel/logs
WORKDIR /kannel/sources-kannel/trunk/gwlib/
RUN make clean
RUN make

# RUN ldconfig

EXPOSE 13013 13000 2346 13015

CMD /usr/local/sbin/bearerbox -v 1 /kannel/conf-kannel/kannel.conf