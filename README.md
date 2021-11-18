# alpine based rsync server

A rsync/sshd server for storing/providing files. This image can support rsync, scp and sftp access (via docker build arguments). As default only rsync over ssh is enabled.

Access is only allowed via public key authentication.

This docker container uses two volumes:
 - /home/data - base path for storing data
 - /var/local/etc/ssh - volume to store host keys and authorized_keys to connect via ssh


## run container

```
docker run -p 2200:22 -e AUTHORIZED_KEYS="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjWn9ccu2hU/5o5CYbz4qj5FW+7SGgby39rgVHOqGuQ test-key" -v rsync_ssh:/var/local/etc/ssh -v rsync_data:/home/data rsync-server:latest
```

This create two volumes `rsync_ssh` and `rsync_data` to store persistent data. `rsync_ssh` has the generated SSH host keys, `rsync_data` will receive all files.

```
rsync -av -e "ssh -p 2200" mydir data@<docker-host>:
```

will sync your local `mydir` directory to the `rsync_data` volume of the docker host.

## Options


### enable scp, sftp and/or rsync

Use the build-args `RSYNC`, `SCP` and `SFTP` to enable/disable those protocols. As default RSYNC and SCP are enabled.

```
docker build -t rsync-server --build-arg SCP=1 --build-arg SFTP=1 --build-arg RSYNC=0  .
```

You can also use the `ALLOWED_OPTIONS` enviroment variable to enable services during container start, this overrrides the build settings.

```
docker run -p 2200:22 -e ALLOWED_OPTIONS="allowrsync\n allowscp" rsync-server:latest
```

### username

You can use the build-args `USER`, `UID` and `GID` to specify user name and numeric user/group id.

Defaults are `USER=data`, `UID=1000`, `GID=1000`.

```
docker build -t rsync-server --build-arg USER=user --build-arg UID=500  .
```

Then you can use `user@container`, and your volume needs to be `/home/user`.

### authorized_keys

There are three different ways to specifiy authorized keys for ssh access.

1. Specify authorized_keys at container startup via an environment var

 ```
 docker run -p 2200:22 -e AUTHORIZED_KEYS="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjWn9ccu2hU/5o5CYbz4qj5FW+7SGgby39rgVHOqGuQ test-key" rsync-server:latest
 ```

2. Bind mount an existing file

```
docker run -p 2200:22 -v /home/user/.ssh/authorized_keys:/etc/ssh/authorized_keys:ro rsync-server:latest
```

3. Put authorized_keys in a volume

When building the container you can use the AUTH_DIR build variable to place the `authorized_keys` file in the ssh key volume

```
docker build -t rsync-server --build-arg AUTHDIR=/var/local/etc/ssh  .
```

Then mount the ssh key volume to some directory and modify the authorized files directly (as root).

```
docker run -p 2200:22 --name rsync-server -v $HOME/rsync_ssh:/var/local/etc/ssh rsync-server:latest
```

In this case `$HOME/rsync_ssh` will contain ssh host keys and the `authorized_keys` file.

### chroot

No chroot is setup, so the data user can read system files outside his home directory via rsync/scp/sftp. But as this is only a small docker container I didn't spend any time to prevent this.
