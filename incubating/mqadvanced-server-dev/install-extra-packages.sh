#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2019
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

test -f /usr/bin/yum && RHEL=true || RHEL=false
test -f /usr/bin/apt-get && UBUNTU=true || UBUNTU=false

if ($UBUNTU); then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends sudo
    rm -rf /var/lib/apt/lists/*
fi

if ($RHEL); then
    yum -y install sudo
    yum -y clean all
    rm -rf /var/cache/yum/*
fi
