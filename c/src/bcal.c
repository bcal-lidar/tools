// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/*
** Main executable for the bcal lidar tools.  See the corresponding folders for
** tool documentation (eg filter/ for the filter tool).
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "bcal_filter.h"

void Usage()
{
    printf(
"bcal <tool> [options] arguments\n"
"\n"
"   tools: filter\n" );
    exit(1);
}

int main( int argc, char *argv[] )
{
    unsigned int i = 1;
    if( argc < 2 )
    {
        Usage();
    }

    if( strncmp( argv[i], "filter", strlen( "filter" ) ) == 0 )
    {
        return bcal_filter_app( argc, argv );
    }
    else
    {
        Usage();
    }
    i++;
    return 0;
}
