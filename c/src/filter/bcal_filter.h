// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef BCAL_FILTER_H_
#define BCAL_FILTER_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bcal_point.h"
#include "bcal_types.h"

#include <gdal.h>

typedef OGREnvelope bcal_env;

typedef struct bcal_filter_data
{
    char *input;
    char *output;
    int jobs;
    double merge_buf;
    double spacing;
} bcal_filter_data;

typedef struct bcal_domain
{
    bcal_env env;
    bcal_env *sub_envs;
    uint32 n;
} bcal_domain;

typedef struct bcal_decomposition
{
    uint32 n;
    bcal_env *envs;
} bcal_decomposition;

typedef struct bcal_working_set
{
    uint32 n;
    bcal_env env;
    bcal_point *p;
    double spacing;
} bcal_working_set;

int bcal_filter_app( int argc, char *argv[] );

CPLErr bcal_filter( bcal_filter_data *b);

CPLErr bcal_partition( bcal_domain *d, uint32 jobs );

CPLErr bcal_bin( bcal_working_set *s );

#endif /* BCAL_FILTER_H_ */

