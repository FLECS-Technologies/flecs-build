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

set(PKGBUILD_DIR ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/pkg)

# copy generic pkg directory
install(
    DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/../../pkg/
    DESTINATION ${PKGBUILD_DIR}
    USE_SOURCE_PERMISSIONS
)

# copy target-specific pkg directory
install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/pkg/
    DESTINATION ${PKGBUILD_DIR}
    USE_SOURCE_PERMISSIONS
    PATTERN "fs" EXCLUDE
)

# copy target-specific additional pkg files, if exist
install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/pkg/fs/
    DESTINATION ${PKGBUILD_DIR}/debian
    USE_SOURCE_PERMISSIONS
    OPTIONAL
)
install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/pkg/fs/
    DESTINATION ${PKGBUILD_DIR}/tar
    USE_SOURCE_PERMISSIONS
    OPTIONAL
)

# command for building .deb packages
add_custom_command(
    OUTPUT ${CMAKE_INSTALL_PREFIX}/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.deb
    DEPENDS ${PACKAGE}_deb-pkg-prepare
    COMMAND mkdir -p ${CMAKE_INSTALL_PREFIX}/pkg
    COMMAND dpkg-deb --root-owner-group -Z gzip --build ${PKGBUILD_DIR}/debian ${CMAKE_INSTALL_PREFIX}/pkg/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.deb
)

if(NOT TARGET ${PACKAGE}_deb-pkg-copy)
    add_custom_target(${PACKAGE}_deb-pkg-copy)
endif()

# prepare package control fields with target information
add_custom_target(
    ${PACKAGE}_deb-pkg-prepare
    DEPENDS ${PACKAGE}_deb-pkg-copy
    COMMAND sed -i "s/##ARCH##/${ARCH}/g" ${PKGBUILD_DIR}/debian/DEBIAN/control
    COMMAND sed -i "s/##PACKAGE##/${PACKAGE}/g" ${PKGBUILD_DIR}/debian/DEBIAN/*
    COMMAND sed -i "s/##VERSION##/${PACKAGE_VERSION}/g" ${PKGBUILD_DIR}/debian/DEBIAN/*
    COMMAND sed -i "s/##DESCRIPTION##/${PACKAGE_DESC}/g" ${PKGBUILD_DIR}/debian/DEBIAN/*
    COMMAND sed -i "s/##DEPENDS##/${PACKAGES_DEPENDS}/g" ${PKGBUILD_DIR}/debian/DEBIAN/*
    COMMAND chmod 755 ${PKGBUILD_DIR}/debian/DEBIAN/p* || true
    COMMAND chmod 644 ${PKGBUILD_DIR}/debian/DEBIAN/control
)

# command for creating .tar archives
add_custom_command(
    OUTPUT ${CMAKE_INSTALL_PREFIX}/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.tar
    DEPENDS ${PACKAGE}_deb-pkg-prepare
    COMMAND fakeroot tar -C ${PKGBUILD_DIR}/tar -cvf ${CMAKE_INSTALL_PREFIX}/pkg/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.tar .
)

# generic package rule, depends on .deb and .tar builds
add_custom_target(
    ${PACKAGE}_package
    DEPENDS ${CMAKE_INSTALL_PREFIX}/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.deb
    DEPENDS ${CMAKE_INSTALL_PREFIX}/${PACKAGE}_${PACKAGE_VERSION}_${ARCH}.tar
)

set_property(GLOBAL APPEND PROPERTY PACKAGES ${PACKAGE}_package)
