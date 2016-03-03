// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef BCAL_FILTER_H_
#define BCAL_FILTER_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bcal_types.h"

#include <gdal.h>

typedef struct bcal_filter_data
{
    char *szInputFile;
    char *szOutputFile;
    int nJobs;
    int nMemBufSize;
    double dfMergeBuffer;
    double dfGridSpacing;
}bcal_filter_data;

typedef struct bcal_decomposition
{
    uint32 n;
    OGREnvelope *envs;
} bcal_decomposition;

int bcal_filter_app( int argc, char *argv[] );

CPLErr bcal_filter( bcal_filter_data *b);

CPLErr bcal_partition( OGREnvelope *e, uint32 nMegaBytes, bcal_decomposition *d );

#endif /* BCAL_FILTER_H_ */

