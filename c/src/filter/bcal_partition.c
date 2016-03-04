// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"
#include "bcal_point.h"

#include "gdal.h"
#include "cpl_conv.h"

/*
** bcal_partiiton partitions a domain into tiles.  These tiles will be spread
** over threads to do work.
*/
CPLErr bcal_partition( bcal_domain *d, uint32 jobs )
{
    if( d == NULL )
    {
        return CE_Failure;
    }
    if( jobs == 1 )
    {
        d->sub_envs = malloc( sizeof( OGREnvelope ) );
        d->sub_envs[0] = d->env;
        d->n = 1;
        return CE_None;
    }
    uint32 env_count = 0;
    while( env_count * env_count < jobs )
    {
        env_count++;
    }
    uint32 ec2 = env_count * env_count;
    CPLDebug( "BCAL", "partitioning domain into %d fields", env_count );
    double x, y;
    double dx, dy;
    x = d->env.MinX;
    y = d->env.MaxY;
    dx = (d->env.MaxX - d->env.MinX) / (double)env_count;
    dy = (d->env.MaxY - d->env.MinY) / (double)env_count;
    CPLDebug( "BCAL", "using dx:%lf and dy:%lf to build grid", dx, dy );
    d->sub_envs = malloc( sizeof( bcal_env ) * ec2 );
    d->n = ec2;
    int i, j, k;
    for( i = 0; i < env_count; i++ )
    {
        for( j = 0; j < env_count; j++ )
        {
            d->sub_envs[i+j].MinX = x + dx * j;
            d->sub_envs[i+j].MaxX = x + (dx * (j + 1));
            d->sub_envs[i+j].MaxY = y + dy * i;
            d->sub_envs[i+j].MinY = y - (dy * (j + 1));
            CPLDebug( "BCAL", "using envelope:{%lf,%lf,%lf,%lf} for grid",
                      d->sub_envs[i].MinX, d->sub_envs[i].MaxX,
                      d->sub_envs[i].MinY, d->sub_envs[i].MinY );
        }
    }
    return CE_None;
}

void bcal_free_decomp( bcal_domain *d )
{
    free( d->sub_envs );
    d->sub_envs = NULL;
}
