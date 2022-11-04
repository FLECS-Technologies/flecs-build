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

set(REGISTRY_USER $ENV{REGISTRY_USER})
set(REGISTRY_AUTH $ENV{REGISTRY_AUTH})

if(NOT DOCKER_TAG)
    if(NOT NDEBUG)
        set(DOCKER_TAG ${VERSION}-dev)
    else()
        set(DOCKER_TAG ${VERSION})
    endif()
endif()

add_custom_command(
    OUTPUT ${DOCKER_IMAGE}_buildx
    COMMAND docker buildx build --load --build-arg MACHINE=${MACHINE} --build-arg ARCH=${ARCH} --build-arg VERSION=${VERSION} --platform ${DOCKER_ARCH} --tag flecs/${DOCKER_IMAGE}:${DOCKER_TAG} ${CMAKE_CURRENT_BINARY_DIR}
)

add_custom_command(
    OUTPUT ${DOCKER_IMAGE}_archive
    DEPENDS ${DOCKER_IMAGE}_buildx
    COMMAND docker save flecs/${DOCKER_IMAGE}:${DOCKER_TAG} --output ${CMAKE_CURRENT_BINARY_DIR}/${DOCKER_IMAGE}_${VERSION}_${ARCH}.tar.gz
)

if(NOT TARGET ${DOCKER_IMAGE}_prepare)
    add_custom_target(${DOCKER_IMAGE}_prepare)
endif()

add_custom_target(
    ${DOCKER_IMAGE}_docker
    DEPENDS ${DOCKER_IMAGE}_prepare
    DEPENDS ${DOCKER_IMAGE}_buildx
    DEPENDS ${DOCKER_IMAGE}_archive
)

install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/Dockerfile
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
)

set_property(GLOBAL APPEND PROPERTY DOCKER_IMAGES ${DOCKER_IMAGE}_docker)
