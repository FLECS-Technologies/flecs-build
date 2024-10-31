# Copyright 2021-2023 FLECS Technologies GmbH
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

include(${CMAKE_CURRENT_LIST_DIR}/cflags.cmake)

SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR armhf)

SET(CMAKE_AR arm-linux-gnueabihf-ar)
SET(CMAKE_AS arm-linux-gnueabihf-as)
SET(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
SET(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
SET(CMAKE_LD arm-linux-gnueabihf-ld)
SET(CMAKE_NM arm-linux-gnueabihf-nm)
SET(CMAKE_STRIP arm-linux-gnueabihf-strip)
SET(CMAKE_OBJCOPY arm-linux-gnueabihf-objcopy)
SET(CMAKE_OBJDUMP arm-linux-gnueabihf-objdump)
SET(CMAKE_RANLIB arm-linux-gnueabihf-ranlib)
SET(CMAKE_READELF arm-linux-gnueabihf-readelf)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

SET(CROSS_COMPILE arm-linux-gnueabihf)

SET(RUSTC_TARGET armv7-unknown-linux-gnueabihf)
set(ENV{RUSTFLAGS} \"-Clinker=${CMAKE_C_COMPILER}\")
