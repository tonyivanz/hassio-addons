ARG BUILD_FROM
FROM $BUILD_FROM

# Install AutoSSH and OpenSSH client
RUN apk add --no-cache \
    autossh \
    openssh-client

# Copy the run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]