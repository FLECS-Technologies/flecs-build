#!/bin/bash

## Copyright 2021-2022 FLECS Technologies GmbH
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

run () {
  $* || exit $?
}

run apt-get update
run apt-get --yes --no-install-recommends install $@
run apt-get --yes clean

run rm -rf /var/lib/apt/lists/*
