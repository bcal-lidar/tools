// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
** bin cycles through and assigns a bin based on a canopy spacing.  The bin
** value is stored in each point, then the points are sorted by bin.
*/

#include "bcal_filter.h"

static int compare( const void *a, const void *b )
{
    return ((bcal_point*)a)->bin - ((bcal_point*)b)->bin;
}

CPLErr bcal_bin( bcal_working_set *s )
{
    CPLDebug( "BCAL", "Sorting points into bins for initial ground classification." );
    double dx, dy;
    dx = s->env.MaxX - s->env.MinX;
    dy = s->env.MaxY - s->env.MinY;
    uint32 nx = (dx / s->spacing) + 1;
    uint32 ny = (dy / s->spacing) + 1;
    uint32 i;
    uint32 x, y;
    for( i = 0; i < s->n; i++ )
    {
        x = (s->p[i].x - s->env.MinX) / s->spacing;
        y = (s->env.MaxY - s->p[i].y) / s->spacing;
        s->p[i].bin = y * nx + x;
    }
    qsort( s->p, s->n, sizeof( bcal_point ), *compare );
    return CE_None;
}

