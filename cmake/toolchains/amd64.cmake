# Copyright 2021-2022 FLECS Technologies GmbH
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
SET(CMAKE_SYSTEM_PROCESSOR amd64)

SET(CMAKE_AR ar)
SET(CMAKE_AS as)
SET(CMAKE_C_COMPILER gcc)
SET(CMAKE_CXX_COMPILER g++)
SET(CMAKE_LD ld)
SET(CMAKE_NM nm)
SET(CMAKE_STRIP strip)
SET(CMAKE_OBJCOPY objcopy)
SET(CMAKE_OBJDUMP objdump)
SET(CMAKE_RANLIB ranlib)
SET(CMAKE_READELF readelf)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

SET(CROSS_COMPILE)
