# Copyright 2016 Boise State University.  All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 2.8.8)

include_directories(${PROJECT_SOURCE_DIR}/src
                    ${GDAL_INCLUDE_DIR})
set(bcal_filter_src bcal_filter.c
                    bcal_partition.c)

add_library(filter OBJECT ${bcal_filter_src})

