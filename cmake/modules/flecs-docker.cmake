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
    message(FATAL_ERROR "Cannot build Docker image without tagname")
endif()

add_custom_command(
    OUTPUT ${DOCKER_IMAGE}_buildx
    COMMAND docker buildx build --load --build-arg MACHINE=${MACHINE} --build-arg ARCH=${ARCH} --platform ${DOCKER_ARCH} --tag flecs/${DOCKER_IMAGE}:${DOCKER_TAG} ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}
)

add_custom_command(
    OUTPUT ${DOCKER_IMAGE}_archive
    DEPENDS ${DOCKER_IMAGE}_buildx
    COMMAND docker save flecs/${DOCKER_IMAGE}:${DOCKER_TAG} --output ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${DOCKER_IMAGE}_${DOCKER_TAG}_${ARCH}.tar
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
set_target_properties(
    ${DOCKER_IMAGE}_docker PROPERTIES
    DOCKER_ARCHIVE ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${DOCKER_IMAGE}_${DOCKER_TAG}_${ARCH}.tar
)

install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/Dockerfile
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}
)

install(CODE
    "execute_process(COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target ${DOCKER_IMAGE}_docker RESULT_VARIABLE res ERROR_VARIABLE err)
    if (NOT res EQUAL 0)
        message(FATAL_ERROR \"${err}\")
    endif()"
)

set_property(GLOBAL APPEND PROPERTY DOCKER_IMAGES ${DOCKER_IMAGE}_docker)
