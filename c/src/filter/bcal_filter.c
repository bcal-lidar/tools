// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"
#include "bcal_point.h"

static void Usage()
{
    printf(
"bcal filter [-jobs n] [-mem_limit n/all] [-buffer f]\n"
"            [grid_space f] input output\n"
"\n"
"   -jobs           how many parallel threads to run.\n"
"   -mem_limit      how much estimated memory to use per job,\n"
"                   all meaning don't buffer the work, just run\n"
"                   the entire file over the jobs.\n"
"   -buffer         when merging working tiles, use a buffer of f\n"
"                   overlap.\n"
"   -grid_space     estimated canopy spacing.\n"
"   input           the input *.las or *.laz file\n"
"   output          the output las file (laz writing not supported)\n" );
    exit( 1 );
}

int bcal_filter_app( int argc, char *argv[] )
{
    int i = 0;
    int nJobs = 1;
    int nMemSize = 0;
    double dfBufSize = 0;
    const char *szInput;
    const char *szOutput;
    /* Absolute minimum is 4 arguments. bcal filter in out */
    if( argc < 4 )
    {
        Usage();
    }

    i = 2;
    while( i < argc )
    {
        if( strncmp( argv[i], "-help", strlen( "-help" ) ) == 0 )
        {
            Usage();
        }
        else if( strncmp( argv[i], "-jobs", strlen( "-jobs" ) ) == 0 && i + 1 < argc )
        {
            nJobs = atoi( argv[++i] );
        }
        else if( strncmp( argv[i], "-mem_limit", strlen( "-mem_limit" ) ) == 0 && i + 1 < argc )
        {
            i++;
            if( strncmp( argv[i], "all", strlen( "all" ) == 0 ) )
            {
                nMemSize = 0;
            }
            else
            {
                nMemSize = atoi( argv[i] );
            }
        }
        else if( strncmp( argv[i], "-buffer", strlen( "-buffer" ) ) == 0 && i + 1 < argc )
        {
            dfBufSize = atof( argv[++i] );
        }
        else if( szInput == NULL )
        {
            szInput = argv[i];
        }
        else if( szOutput == NULL )
        {
            szOutput = argv[i];
        }
        i++;
    }
    if( szInput == NULL )
    {
        fprintf( stderr, "No input specified\n" );
        exit( 1 );
    }
    if( szOutput == NULL )
    {
        fprintf( stderr, "No output specified\n" );
        exit( 1 );
    }

    bcal_filter_data b;
    b.szInputFile = strdup( szInput );
    b.szOutputFile = strdup( szOutput );
    b.nJobs = nJobs;
    b.nMemBufSize = nMemSize;
    b.dfMergeBuffer = dfBufSize;

    return (int)bcal_filter( &b );
}

CPLErr bcal_filter( bcal_filter_data *b )
{
    if( b == NULL )
    {
        return CE_Failure;
    }

    //const char * aszValidDrivers = {"LAS", NULL};

    CPLErr eErr = CE_None;
    GDALDatasetH hDS = NULL;
    hDS = GDALOpenEx( b->szInputFile, GDAL_OF_VECTOR | GDAL_OF_READONLY,
                        NULL, NULL, NULL );
    if( hDS == NULL )
    {
        /* GDAL will report a proper failed to open error. */
        return CE_Failure;
    }

    OGRLayerH hLayer = GDALDatasetGetLayer( hDS, 0 );
    if( hLayer == NULL )
    {
        CPLError( CE_Failure, CPLE_AppDefined,
                  "Failed to fetch a valid las layer." );
        GDALClose( hDS );
        return CE_Failure;
    }

    OGREnvelope sDomain;
    if( OGR_L_GetExtent( hLayer, &sDomain, FALSE ) != OGRERR_NONE )
    {
        CPLError( CE_Failure, CPLE_AppDefined,
                  "Failed to obtain a valid domain boundary." );
        GDALClose( hDS );
        return CE_Failure;
    }

    bcal_decomposition d;

    eErr = bcal_partition( &sDomain, b->nJobs, &d );
    if( eErr != CE_None )
    {
        CPLError( CE_Failure, CPLE_AppDefined,
                  "Failed to partition domain" );
        GDALClose( hDS );
        return CE_Failure;
    }
    /*
    ** We could use fast feature count here, when spatial filter enabled.
    ** Instead, we'll guess and keep track.
    */
    uint64 nGuess = OGR_L_GetFeatureCount( hLayer, FALSE ) / d.n;
    int nAlloc = nGuess;
    bcal_point **points;
    points = malloc( sizeof( bcal_point* ) * d.n );
    OGRGeometryH hPoly;
    OGRGeometryH hRing;
    OGRGeometryH hGeom;
    OGRFeatureH hFeat;
    uint32 i, j;
    for( i = 0; i < d.n; i++ )
    {
        nAlloc = nGuess;
        points[i] = malloc( sizeof( bcal_point ) * nAlloc );
        hRing = OGR_G_CreateGeometry( wkbLinearRing );
        hPoly = OGR_G_CreateGeometry( wkbPolygon );
        OGR_G_SetPoint( hRing, 0, d.envs[i].MinX, d.envs[i].MaxY, 0 );
        OGR_G_SetPoint( hRing, 1, d.envs[i].MaxX, d.envs[i].MaxY, 0 );
        OGR_G_SetPoint( hRing, 2, d.envs[i].MinX, d.envs[i].MinY, 0 );
        OGR_G_SetPoint( hRing, 3, d.envs[i].MaxX, d.envs[i].MinY, 0 );
        OGR_G_CloseRings( hRing );
        OGR_G_AddGeometry( hPoly, hRing );
        OGR_L_ResetReading( hLayer );
        OGR_L_SetSpatialFilter( hLayer, hPoly );
        j = 0;
        while( (hFeat = OGR_L_GetNextFeature( hLayer )) != NULL )
        {
            if( j >= nAlloc )
            {
                nAlloc = nAlloc * 1.5;
                points[i] = realloc( points[i], sizeof( bcal_point ) * nAlloc );
            }
            points[i][j].fid = OGR_F_GetFID( hFeat );
            points[i][j].c =
                OGR_F_GetFieldAsInteger( hFeat, OGR_F_GetFieldIndex( hFeat, "classification" ) );
            hGeom = OGR_F_GetGeometryRef( hFeat );
            points[i][j].x = OGR_G_GetX( hGeom, 0 );
            points[i][j].y = OGR_G_GetY( hGeom, 0 );
            points[i][j].z = OGR_G_GetZ( hGeom, 0 );
            OGR_F_Destroy( hFeat );
            j++;
        }
        /* Free unused array stuff */
        points[i] = realloc( points[i], sizeof( bcal_point ) * (j - 1) );
        OGR_L_SetSpatialFilter( hLayer, NULL );
        OGR_G_DestroyGeometry( hRing );
        OGR_G_DestroyGeometry( hPoly );
    }
    for( i = 0; i < d.n; i++ )
    {
        free( points[i] );
        points[i] = NULL;
    }
    free( points );
    points = NULL;

    GDALClose( hDS );
    return CE_None;
}

