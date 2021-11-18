FROM alpine:latest

LABEL version="1.1"
LABEL description="Data storage via rsync/ssh (or scp/sftp if enabled)"

ARG UID=1000 GID=1000 USER=data RSYNC=1 SCP=1 SFTP=0 AUTHDIR

ENV SSH_KEYS_DIR=/var/local/etc/ssh AUTHORIZED_KEYS_FILE=${AUTHDIR:-/etc/ssh}/authorized_keys DATA_USER=$USER DATA_DIR=/home/$USER

# user: don't use passwd, but with ! in etc/shadow sshd will refuse to "locked" account, so
#       replace it with * which is an invalid password but for sshd and key based auth it is ok
# remove write permissions to /tmp to avoid that data user can place files in /tmp directory
#       /tmp isn't needed in this implementation

RUN apk add --no-cache bash rssh rsync ;\
    addgroup -g $GID $USER ;\
    adduser -D -G $USER -u $UID -h $DATA_DIR -s /usr/bin/rssh $USER ;\
    sed -i 's/!/*/' /etc/shadow ;\
    mkdir -p -m 0755 $SSH_KEYS_DIR ;\
    mv /etc/rssh.conf.default /etc/rssh.conf ;\
    if [ $RSYNC -eq 1 ]; then echo "allowrsync" >> /etc/rssh.conf; fi ;\
    if [ $SCP -eq 1 ]; then echo "allowscp" >> /etc/rssh.conf; fi ;\
    if [ $SFTP -eq 1 ]; then echo "allowsftp" >> /etc/rssh.conf; fi ;\
    chmod 0775 /tmp

COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /

RUN echo "AuthorizedKeysFile $AUTHORIZED_KEYS_FILE" >> /etc/ssh/sshd_config

CMD ["/entrypoint.sh"]
EXPOSE 22
VOLUME $DATA_DIR
VOLUME $SSH_KEYS_DIR
