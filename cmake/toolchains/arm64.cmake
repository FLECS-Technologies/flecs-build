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

SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR arm64)

SET(CMAKE_AR aarch64-linux-gnu-ar)
SET(CMAKE_AS aarch64-linux-gnu-as)
SET(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
SET(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
SET(CMAKE_LD aarch64-linux-gnu-ld)
SET(CMAKE_NM aarch64-linux-gnu-nm)
SET(CMAKE_STRIP aarch64-linux-gnu-strip)
SET(CMAKE_OBJCOPY aarch64-linux-gnu-objcopy)
SET(CMAKE_OBJDUMP aarch64-linux-gnu-objdump)
SET(CMAKE_RANLIB aarch64-linux-gnu-ranlib)
SET(CMAKE_READELF aarch64-linux-gnu-readelf)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

SET(CROSS_COMPILE aarch64-linux-gnu)

SET(RUSTC_TARGET aarch64-unknown-linux-gnu)
set(ENV{RUSTFLAGS} \"-Clinker=${CMAKE_C_COMPILER}\")
