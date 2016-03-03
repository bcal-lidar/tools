# Copyright 2016 Boise State University.  All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 2.8.8)

project(bcal)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules/")

if(NOT MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
else(NOT MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-D_SCL_SECURE_NO_WARNINGS)
endif(NOT MSVC)

include(FindGDAL)
find_package(GDAL REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

add_subdirectory(src)

include(CTest)
enable_testing()

if(BUILD_TESTING)
    add_subdirectory(test)
endif(BUILD_TESTING)

# CPack related
include(InstallRequiredSystemLibraries)

set(BCAL_NAME "bcal")
set(BCAL_VERSION_MAJOR 0)
set(BCAL_VERSION_MINOR 0)
set(BCAL_VERSION_PATCH 0)
set(BCAL_VERSION_NAME "bcal-${BCAL_VERSION_MAJOR}.${BCAL_VERSION_MINOR}.${BCAL_VERSION_PATCH}")
set(BCAL_VERSION "${BCAL_VERSION_MAJOR}.${BCAL_VERSION_MINOR}.${BCAL_VERSION_PATCH}")

if(CMAKE_BUILD_TYPE)
    string(TOLOWER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
else()
    set(BUILD_TYPE "debug")
endif()

# *****************************************************************************
# CPack variables
# *****************************************************************************
if(WIN32)
    set(CPACK_NSIS_PACKAGE_NAME ${BCAL_VERSION_NAME})
    set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/LICENSE")
    set(CPACK_VERSION_MAJOR ${BCAL_VERSION_MAJOR})
    set(CPACK_VERSION_MINOR ${BCAL_VERSION_MINOR})
    set(CPACK_VERSION_PATCH ${BCAL_VERSION_PATCH})
    set(CPACK_PACKAGE_VERSION ${BCAL_VERSION})

    set(CPACK_NSIS_INSTALL_ROOT "C:")
    cmake_policy(PUSH)
    cmake_policy(SET CMP0010 OLD)
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "${BCAL_NAME}\\\\${BCAL_VERSION_NAME}")
    set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${BCAL_NAME}\\\\${BCAL_VERSION_NAME}")
    cmake_policy(POP)
    set(CPACK_NSIS_DISPLAY_NAME "${BCAL_NAME}\\\\${BCAL_VERSION_NAME}")

    set(CPACK_CREATE_DESKTOP_LINKS ${BCAL_NAME})
    set(CPACK_NSIS_MODIFY_PATH ${BCAL_NAME})

    set(CPACK_PACKAGE_EXECUTABLES "bcal" ${BCAL_VERSION_NAME})

    get_filename_component(GDAL_INSTALL_PATH ${GDAL_LIBRARY} DIRECTORY)
    get_filename_component(GDAL_INSTALL_PATH ${GDAL_INSTALL_PATH} DIRECTORY)
    message(STATUS "Using ${GDAL_INSTALL_PATH} for GDAL_HOME")

    install(FILES ${PROJECT_SOURCE_DIR}/README.md DESTINATION doc)

    install(PROGRAMS "${GDAL_INSTALL_PATH}/bin/gdal200.dll" DESTINATION bin)
    install(PROGRAMS "${GDAL_INSTALL_PATH}/bin/gdal_translate.exe" DESTINATION bin)
    install(PROGRAMS "${GDAL_INSTALL_PATH}/bin/gdalbuildvrt.exe" DESTINATION bin)
    # gdal data
endif(WIN32)

Include(CPack)

