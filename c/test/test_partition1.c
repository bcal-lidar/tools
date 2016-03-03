// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"

int main()
{
    OGREnvelope env;
    env.MinX = 0.;
    env.MaxX = 10.;
    env.MinY = 0.;
    env.MaxY = 10.;
    bcal_decomposition d;
    CPLErr e = bcal_partition( &env, 4, &d );
    if( e != CE_None )
    {
        return 1;
    }
    if( d.n != 4 )
    {
        return 1;
    }
    if( !CPLIsEqual( d.envs[0].MinX, 0. ) ||
        !CPLIsEqual( d.envs[0].MaxX, 5. ) ||
        !CPLIsEqual( d.envs[0].MinY, 5. ) ||
        !CPLIsEqual( d.envs[0].MaxY, 10. ) )
    {
        return 1;
    }
    bcal_free_decomp( &d );
    return 0;
}

