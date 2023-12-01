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

cmake_minimum_required(VERSION 3.21)

if(PROJECT_NAME)
    message(FATAL_ERROR "Please include flecs-build before defining any projects")
endif()

set(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    ${CMAKE_CURRENT_LIST_DIR}/modules
)

# set default CXX flags
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS OFF)
add_compile_options(-Wall -Wextra -Werror -Wfatal-errors)
link_libraries(dl pthread stdc++fs)

# hide all symbols by default
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
add_link_options(-Wl,--exclude-libs,ALL)

# provide macro to export symbols
add_definitions("-DFLECS_EXPORT=__attribute__((visibility(\"default\")))")

# set target toolchain, if ARCH is provided
if(ARCH)
    set(USER_ARCH ${ARCH})

    if("${ARCH}" STREQUAL "amd64")
        set(TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/toolchains/amd64.cmake)
    elseif("${ARCH}" STREQUAL "arm64")
        set(TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/toolchains/arm64.cmake)
    elseif("${ARCH}" STREQUAL "armhf")
        set(TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/toolchains/armhf.cmake)
    else()
        message(FATAL_ERROR "Invalid target architecture ${ARCH} specified")
    endif()
endif()

if(TOOLCHAIN_FILE)
    message(STATUS "Using toolchain from ${TOOLCHAIN_FILE}")
    include(${TOOLCHAIN_FILE})
else()
    enable_language(CXX)
endif()

# set MACHINE and ARCH variables
execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -dumpmachine
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE MACHINE
)

if("${MACHINE}" MATCHES ".*x86_64.*")
    set(ARCH amd64)
    set(DOCKER_ARCH linux/amd64)
elseif("${MACHINE}" STREQUAL arm-linux-gnueabihf)
    set(ARCH armhf)
    set(DOCKER_ARCH linux/arm/v7)
elseif("${MACHINE}" STREQUAL aarch64-linux-gnu)
    set(ARCH arm64)
    set(DOCKER_ARCH linux/arm64)
else()
    message(FATAL_ERROR "Could not determine architecture for ${MACHINE} from ${CMAKE_CXX_COMPILER}")
endif()

message(STATUS "Detected target machine ${MACHINE}")

if(USER_ARCH AND NOT("${USER_ARCH}" STREQUAL "${ARCH}"))
    message(FATAL_ERROR "Mismatch between specified and detected architecture")
endif()

# use ccache, if not disabled
if(NOT NO_CCACHE)
    execute_process(
        COMMAND ccache -s
        OUTPUT_QUIET
        ERROR_QUIET
        RESULT_VARIABLE CCACHE_FOUND
    )

    if(CCACHE_FOUND EQUAL 0)
        message(STATUS "Setting ccache as compiler launcher")
        set(CMAKE_C_COMPILER_LAUNCHER ccache)
        set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
    endif()
endif()
