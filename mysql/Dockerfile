FROM mysql


# Every file that need to be run when the container is built go here
COPY /build/*.sql /docker-entrypoint-initdb.d/

# We replace the default values by the ones set in .env for the push
ARG PUSH_DATABASE
ARG PUSH_USER
ARG PUSH_PASSWORD

RUN sed -i "s/push_database/${PUSH_DATABASE}/g" /docker-entrypoint-initdb.d/push.sql
RUN sed -i "s/push_user/${PUSH_USER}/g" /docker-entrypoint-initdb.d/push.sql
RUN sed -i "s/push_password/${PUSH_PASSWORD}/g" /docker-entrypoint-initdb.d/push.sql

# We replace the default values by the ones set in .env for Kannel
ARG KANNEL_DATABASE
ARG KANNEL_USER
ARG KANNEL_PASSWORD

RUN sed -i "s/kannel_database/${KANNEL_DATABASE}/g" /docker-entrypoint-initdb.d/kannel.sql
RUN sed -i "s/kannel_user/${KANNEL_USER}/g" /docker-entrypoint-initdb.d/kannel.sql
RUN sed -i "s/kannel_password/${KANNEL_PASSWORD}/g" /docker-entrypoint-initdb.d/kannel.sql

# Every file that need to be available to be run at a later date goes here

COPY /scripts/*.sql /scripts/

RUN sed -i "s/kannel_database/${KANNEL_DATABASE}/g" /scripts/kannel_update.sql

# The following lines are used to Debug in case you get strange result from the args
# RUN cat /docker-entrypoint-initdb.d/kannel.sql
# RUN cat /docker-entrypoint-initdb.d/push.sql
RUN cat /scripts/kannel_update.sql