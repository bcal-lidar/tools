// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"
#include "bcal_point.h"

#include "gdal.h"
#include "cpl_conv.h"

CPLErr bcal_partition( OGREnvelope *env, uint32 jobs, bcal_decomposition *d )
{
    if( env == NULL || d == NULL )
    {
        return CE_Failure;
    }
    if( jobs == 1 )
    {
        d->envs = malloc( sizeof( OGREnvelope ) );
        d->envs[0] = *env;
        d->n = 1;
        return CE_None;
    }
    uint32 env_count = 0;
    while( env_count * env_count < jobs )
    {
        env_count++;
    }
    CPLDebug( "BCAL", "partitioning domain into %d fields", env_count );
    double x, y;
    double dx, dy;
    x = env->MinX;
    y = env->MaxY;
    dx = (env->MaxX - env->MinX) / (double)env_count;
    dy = (env->MaxY - env->MinY) / (double)env_count;
    CPLDebug( "BCAL", "using dx:%lf and dy:%lf to build grid", dx, dy );
    d->envs = malloc( sizeof( OGREnvelope ) * env_count * env_count );
    d->n = env_count * env_count;
    int i, j, k;
    for( i = 0; i < env_count; i++ )
    {
        for( j = 0; j < env_count; j++ )
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
