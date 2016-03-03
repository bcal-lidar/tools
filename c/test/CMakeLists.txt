# Copyright 2016 Boise State University.  All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 2.8.8)


include_directories(${PROJECT_SOURCE_DIR}/src
                    ${PROJECT_SOURCE_DIR}/src/filter
                    ${GDAL_INCLUDE_DIR})

#set(bcal_objects 

file(GLOB ctests ${PROJECT_SOURCE_DIR}/test/*.c)
foreach(ctest ${ctests})
    get_filename_component(base ${ctest} NAME_WE)
    add_executable(${base} ${ctest} $<TARGET_OBJECTS:filter>)
    target_link_libraries(${base} ${GDAL_LIBRARY})
    add_test(${base} ${base})
endforeach(ctest ${ctests})

