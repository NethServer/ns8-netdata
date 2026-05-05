# ns8-netdata

Netdata collects metrics per second and presents them in beautiful low-latency dashboards. It is designed to run on all of your physical and virtual servers, cloud deployments, Kubernetes clusters, and edge/IoT devices, to monitor your systems, containers, and applications.

## Install

Instantiate the module with:

    add-module ghcr.io/nethserver/netdata:latest 1

The output of the command will return the instance name.
Output example:

    {"module_id": "netdata1", "image_name": "netdata", "image_url": "ghcr.io/nethserver/netdata:latest"}

## Connect Node to netdata
When you want to display  you node in netdata room  the application could ask you to prove that you are well the sysadmin of the agent. A file `netdata_random_session_id` contains some random strings that the netdata application could ask you. To retrieve it:

    podman exec netdata1 cat /var/lib/netdata/netdata_random_session_id

Once you have pasted it you can see the node in the room

You could also register to a room by setting two environment variables inside the file environment `vim environment`

```
NETDATA_CLAIM_ROOMS=
NETDATA_CLAIM_TOKEN=
```

Once done you can restart the service by `systemctl restart netdata1`

## Get the configuration
You can retrieve the configuration with

```
api-cli run get-configuration --agent module/netdata1
```

## Write a custom configuration

https://learn.netdata.cloud/docs/netdata-agent/installation/docker#configure-agent-containers

```
podman  exec -ti netdata1 bash
cd /etc/netdata
#download the configuration example 
curl -o /etc/netdata/netdata.conf2 http://localhost:19999/netdata.conf
# edit the configuration and restart
./edit-config netdata.conf
# exit of the container
exit
systemctl restart netdata1
```

## Uninstall

To uninstall the instance:

    remove-module --no-preserve netdata1

## Debug

some CLI are needed to debug

- The module runs under an agent that initiate a lot of environment variables (in /home/netdata1/.config/state), it could be nice to verify them
on the root terminal

    `runagent -m netdata1 env`

- you can become runagent for testing scripts and initiate all environment variables
  
    `runagent -m netdata1`

 the path become : 
```
    echo $PATH
    /home/netdata1/.config/bin:/usr/local/agent/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/
```

- if you want to debug a container or see environment inside
 `runagent -m netdata1`
 ```
podman ps
CONTAINER ID  IMAGE                                      COMMAND               CREATED        STATUS        PORTS                    NAMES
d292c6ff28e9  localhost/podman-pause:4.6.1-1702418000                          9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  80b8de25945f-infra
d8df02bf6f4a  docker.io/library/mariadb:10.11.5          --character-set-s...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  mariadb-app
9e58e5bd676f  docker.io/library/nginx:stable-alpine3.17  nginx -g daemon o...  9 minutes ago  Up 9 minutes  127.0.0.1:20015->80/tcp  netdata-app
```

you can see what environment variable is inside the container
```
podman exec  netdata1 env
TERM=xterm
container=podman
NETDATA_EXTRA_DEB_PACKAGES=lm-sensors
NETDATA_CLAIM_TOKEN=
NETDATA_CLAIM_ROOMS=
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NETDATA_OFFICIAL_IMAGE=true
DOCKER_GRP=netdata
DOCKER_USR=netdata
NETDATA_LISTENER_PORT=19999
DEBIAN_FRONTEND=noninteractive
NETDATA_CLAIM_URL=https://app.netdata.cloud
HOSTNAME=r3-pve.rocky9-pve3.org
HOME=/root
```

you can run a shell inside the container

```
podman exec -ti   netdata1 sh
/ # 
```
## Running tests locally

This module uses the NS8 standard testing infrastructure. For instructions on how to run the test suite locally, refer to the [Running tests locally](https://github.com/NethServer/ns8-github-actions/blob/main/README.md#running-tests-locally) section of the ns8-github-actions documentation.

## UI translation

Translated with [Weblate](https://hosted.weblate.org/projects/ns8/).

To setup the translation process:

- add [GitHub Weblate app](https://docs.weblate.org/en/latest/admin/continuous.html#github-setup) to your repository
- add your repository to [hosted.weblate.org]((https://hosted.weblate.org) or ask a NethServer developer to add it to ns8 Weblate project
