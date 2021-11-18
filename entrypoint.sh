#!/bin/bash
set -euo pipefail

if [ ! -f $SSH_KEYS_DIR/ssh_host_ecdsa_key ]; then
    ssh-keygen -A -f ${SSH_KEYS_DIR%/etc/ssh}  # /etc/ssh is added automatically by ssh-keygen -A
fi

if [[ -n "${AUTHORIZED_KEYS:-}" ]]; then
    echo -e "$AUTHORIZED_KEYS" > "$AUTHORIZED_KEYS_FILE"
else if [ ! -f $AUTHORIZED_KEYS_FILE ]; then
         echo "Missing AUTHORIZED_KEYS variable or $AUTHORIZED_KEYS_FILE file." >&2
         touch $AUTHORIZED_KEYS_FILE
     fi
fi

chmod 0644 $AUTHORIZED_KEYS_FILE || true # chmod fails if $AUTHORIZED_KEYS_FILE is bind mounted

if [[ -n "${ALLOWED_OPTIONS:-}" ]]; then
    echo "$ALLOWED_OPTIONS" > /etc/rssh.conf
fi

if [[ "$(stat -c %U:%G "$DATA_DIR")" != "$DATA_USER:$DATA_USER" ]]; then
    echo Changing owner of "$DATA_DIR" to "$DATA_USER:$DATA_USER" >&2
    chown -R "$DATA_USER":"$DATA_USER" "$DATA_DIR"
fi

# Run sshd on container start
exec /usr/sbin/sshd -D -e
