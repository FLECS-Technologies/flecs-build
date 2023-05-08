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

if (NOT APP_NAME)
    message(FATAL_ERROR "Cannot define App without APP_NAME")
endif()

add_custom_target(
    ${APP_NAME}_app
    COMMAND ;
)

set_target_properties(
    ${APP_NAME}_app PROPERTIES
    MANIFEST ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${APP_NAME}_${APP_VERSION}.json
)

install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/manifest.json
    DESTINATION ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}
    RENAME ${APP_NAME}_${APP_VERSION}.json
)

set_property(GLOBAL APPEND PROPERTY APPS ${APP_NAME}_app)
