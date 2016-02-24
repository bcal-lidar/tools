# Copyright 2016 Boise State University.  All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 2.6)

set(bcal_filter_src filter.cpp)

include_directories(${GDAL_INCLUDE_DIR})

add_executable(${bcal_filter_src} filter)
target_link_libraries(filter ${GDAL_LIBRARY})
install(filter COMPONENT bin)

