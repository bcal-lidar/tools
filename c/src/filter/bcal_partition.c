// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"
#include "bcal_point.h"

#include "gdal.h"
#include "cpl_conv.h"

CPLErr bcal_partition( OGREnvelope *psEnv, uint32 nJobs, bcal_decomposition *d )
{
    if( psEnv == NULL || d == NULL )
    {
        return CE_Failure;
    }
    if( nJobs == 1 )
    {
        d->envs = malloc( sizeof( OGREnvelope ) );
        d->envs[0] = *psEnv;
        d->n = 1;
        return CE_None;
    }
    uint32 nEnv = 0;
    while( nEnv * nEnv < nJobs )
    {
        nEnv++;
    }
    CPLDebug( "BCAL", "partitioning domain into %d fields", nEnv );
    double x, y;
    double dx, dy;
    x = psEnv->MinX;
    y = psEnv->MaxY;
    dx = (psEnv->MaxX - psEnv->MinX) / (double)nEnv;
    dy = (psEnv->MaxY - psEnv->MinY) / (double)nEnv;
    CPLDebug( "BCAL", "using dx:%lf and dy:%lf to build grid", dx, dy );
    d->envs = malloc( sizeof( OGREnvelope ) * nEnv * nEnv );
    d->n = nEnv * nEnv;
    int i, j, k;
    for( i = 0; i < nEnv; i++ )
    {
        for( j = 0; j < nEnv; j++ )
        {
            d->envs[i+j].MinX = x + dx * j;
            d->envs[i+j].MaxX = x + (dx * (j + 1));
            d->envs[i+j].MaxY = y + dy * i;
            d->envs[i+j].MinY = y - (dy * (j + 1));
            CPLDebug( "BCAL", "using envelope:{%lf,%lf,%lf,%lf} for grid",
                      d->envs[i].MinX, d->envs[i].MaxX,
                      d->envs[i].MinY, d->envs[i].MinY );
        }
    }
    return CE_None;
}

void bcal_free_decomp( bcal_decomposition *d )
{
    free( d->envs );
    d->envs = NULL;
}
