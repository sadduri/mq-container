#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2017
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Fail on any non-zero return code
set -ex

export DEBIAN_FRONTEND=noninteractive

# Install additional packages required by MQ, this install process and the runtime scripts
apt-get update
apt-get install -y --no-install-recommends \
  bash \
  bc \
  ca-certificates \
  coreutils \
  curl \
  debianutils \
  file \
  findutils \
  gawk \
  grep \
  libc-bin \
  lsb-release \
  mount \
  passwd \
  procps \
  sed \
  tar \
  util-linux

# Download and extract the MQ installation files
mkdir -p /tmp/mq
cd /tmp/mq
curl -LO $MQ_URL
tar -zxvf ./*.tar.gz

# Recommended: Create the mqm user ID with a fixed UID and group, so that the file permissions work between different images
groupadd --gid 1000 mqm
useradd --uid 1000 --gid mqm mqm
usermod -G mqm root
cd /tmp/mq/DebianMQServer

# Accept the MQ license
./mqlicense.sh -text_only -accept
echo "deb [trusted=yes] file:/tmp/mq/DebianMQServer ./" > /etc/apt/sources.list.d/IBM_MQ.list

# Install MQ using the DEB packages
apt-get update
apt-get install -y $MQ_PACKAGES

# Remove 32-bit libraries from 64-bit container
find /opt/mqm /var/mqm -type f -exec file {} \; | awk -F: '/ELF 32-bit/{print $1}' | xargs --no-run-if-empty rm -f

# Remove tar.gz files unpacked by RPM postinst scripts
find /opt/mqm -name '*.tar.gz' -delete

# Recommended: Set the default MQ installation (makes the MQ commands available on the PATH)
/opt/mqm/bin/setmqinst -p /opt/mqm -i

# Clean up all the downloaded files
rm -f /etc/apt/sources.list.d/IBM_MQ.list
rm -rf /tmp/mq

# Apply any bug fixes not included in base Ubuntu or MQ image.
# Don't upgrade everything based on Docker best practices https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#run
apt-get upgrade -y libkrb5-26-heimdal
apt-get upgrade -y libexpat1

# End of bug fixes
rm -rf /var/lib/apt/lists/*

# Optional: Update the command prompt with the MQ version
echo "mq:$(dspmqver -b -f 2)" > /etc/debian_chroot

# Remove the directory structure under /var/mqm which was created by the installer
rm -rf /var/mqm

# Create the mount point for volumes
mkdir -p /mnt/mqm

# Create the directory for MQ configuration files
mkdir -p /etc/mqm

# Create a symlink for /var/mqm -> /mnt/mqm/data
ln -s /mnt/mqm/data /var/mqm

# Optional: Set these values for the Bluemix Vulnerability Report
sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/' /etc/login.defs
sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t1/' /etc/login.defs
sed -i 's/password\t\[success=1 default=ignore\]\tpam_unix\.so obscure sha512/password\t[success=1 default=ignore]\tpam_unix.so obscure sha512 minlen=8/' /etc/pam.d/common-password