#!/bin/bash

#
# Copyright (C) 2022 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# cleanup on exit
# cleanup_list=()
# trap 'rm -rf "${bouncer_tmp_dir}" clamscan-firewall-bouncer-linux-amd64.tgz' EXIT

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/stephdl}"

# The clamscan-firewall-bouncer versions can be found : https://github.com/crowdsecurity/cs-firewall-bouncer/releases
# curl --netrc --fail -L -o clamscan-firewall-bouncer-linux-amd64.tgz \
#     https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/v0.0.31/clamscan-firewall-bouncer-linux-amd64.tgz

# After updates add the new value to CHECKSUM file: sha256sum clamscan-firewall-bouncer-linux-amd64.tgz > CHECKSUM
# sha256sum -c CHECKSUM

# bouncer_tmp_dir=$(mktemp -d)
# tar -C "${bouncer_tmp_dir}" -x -v -z -f clamscan-firewall-bouncer-linux-amd64.tgz

# Create a new empty container image for clamscan-firewall-bouncer
# reponame="clamscan"
# container=$(buildah from docker.io/clamav/clamav:1.4.2)

# # add to the container the clamscan-firewall-bouncer
# buildah add --chmod 750 ${container} container/test /usr/bin/test

# buildah config \
#     --workingdir="/" \
#     --cmd='["/usr/local/bin/clamscan-firewall-bouncer", "-c", "/etc/clamscan/bouncers/clamscan-firewall-bouncer.yaml"]' \
#     --label="org.opencontainers.image.source=https://github.com/NethServer/ns8-clamscan" \
#     --label="org.opencontainers.image.authors=Stephane de Labrusse <stephdl@de-labrusse.fr>" \
#     --label="org.opencontainers.image.title=Crowdsec-firewall-bouncer based on debian" \
#     --label="org.opencontainers.image.description=A Crowdsec-firewall-bouncer running in a debian container" \
#     --label="org.opencontainers.image.licenses=GPL-3.0-or-later" \
#     --label="org.opencontainers.image.url=https://github.com/NethServer/ns8-clamscan" \
#     --label="org.opencontainers.image.documentation=https://github.com/NethServer/ns8-clamscan/blob/main/README.md" \
#     --label="org.opencontainers.image.vendor=NethServer" \
#     "${container}"

# Commit the image
# buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

# Configure the image name
reponame="clamscan"

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-clamscan container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-clamscan; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-clamscan -v "${PWD}:/usr/src:Z" docker.io/library/node:18-slim
fi

echo "Build static UI files with node..."
buildah run --env="NODE_OPTIONS=--openssl-legacy-provider" nodebuilder-clamscan sh -c "cd /usr/src/ui && yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
buildah config --entrypoint=/ \
    --label="org.nethserver.max-per-node=1" \
    --label="org.nethserver.authorizations=" \
    --label="org.nethserver.rootfull=1" \
    --label="org.nethserver.images=docker.io/clamav/clamav:1.4.2" \
    --label="org.nethserver.tcp-ports-demand=0" \
    "${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github. 
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
    # Set output value for Github Actions
    printf "images=%s\n" "${images[*],,}" >> $GITHUB_OUTPUT
else
    # Just print info for manual push
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
