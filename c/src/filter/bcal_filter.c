// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "bcal_filter.h"
#include "bcal_point.h"

static void Usage()
{
    printf(
"bcal filter [-jobs n] [-buffer f] [grid_space f] input output\n"
"\n"
"   -jobs           how many parallel threads to run.\n"
"   -buffer         when merging working tiles, use a buffer of f\n"
"                   overlap.\n"
"   -grid_space     estimated canopy spacing, default 1.0\n"
"   input           the input *.las or *.laz file\n"
"   output          the output las file (laz writing not supported)\n" );
    exit( 1 );
}

int bcal_filter_app( int argc, char *argv[] )
{
    int i = 0;
    int jobs = 1;
    double merge_buf = 0;
    double spacing = 1.0;
    const char *input = NULL;
    const char *output = NULL;
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
            jobs = atoi( argv[++i] );
        }
        else if( strncmp( argv[i], "-buffer", strlen( "-buffer" ) ) == 0 && i + 1 < argc )
        {
            merge_buf = atof( argv[++i] );
        }
        else if( strncmp( argv[i], "-grid_space", strlen( "-grid_space" ) ) == 0 && i + 1 < argc )
        {
            spacing = atof( argv[++i] );
        }
        else if( input == NULL )
        {
            input = argv[i];
        }
        else if( output == NULL )
        {
            output = argv[i];
        }
        i++;
    }
    if( input == NULL )
    {
        fprintf( stderr, "No input specified\n" );
        exit( 1 );
    }
    if( output == NULL )
    {
        fprintf( stderr, "No output specified\n" );
        exit( 1 );
    }

    bcal_filter_data b;
    b.input = strdup( input );
    b.output = strdup( output );
    b.jobs = jobs;
    b.merge_buf = merge_buf;
    b.spacing = spacing;

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
    hDS = GDALOpenEx( b->input, GDAL_OF_VECTOR | GDAL_OF_READONLY,
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

    bcal_domain domain;
    if( OGR_L_GetExtent( hLayer, &(domain.env), FALSE ) != OGRERR_NONE )
    {
        CPLError( CE_Failure, CPLE_AppDefined,
                  "Failed to obtain a valid domain boundary." );
        GDALClose( hDS );
        return CE_Failure;
    }

    eErr = bcal_partition( &domain, b->jobs );
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
    uint64 guess = OGR_L_GetFeatureCount( hLayer, FALSE ) / domain.n;
    int alloced = guess;
    bcal_working_set *set = malloc( sizeof( bcal_working_set ) * domain.n );
    OGRGeometryH hPoly;
    OGRGeometryH hRing;
    OGRGeometryH hGeom;
    OGRFeatureH hFeat;
    uint32 i, j;
    for( i = 0; i < domain.n; i++ )
    {
        alloced = guess;
        set[i].p = malloc( sizeof( bcal_point ) * alloced );
        set[i].env = domain.sub_envs[i];
        hRing = OGR_G_CreateGeometry( wkbLinearRing );
        hPoly = OGR_G_CreateGeometry( wkbPolygon );
        OGR_G_SetPoint( hRing, 0, domain.sub_envs[i].MinX, domain.sub_envs[i].MaxY, 0 );
        OGR_G_SetPoint( hRing, 1, domain.sub_envs[i].MaxX, domain.sub_envs[i].MaxY, 0 );
        OGR_G_SetPoint( hRing, 2, domain.sub_envs[i].MinX, domain.sub_envs[i].MinY, 0 );
        OGR_G_SetPoint( hRing, 3, domain.sub_envs[i].MaxX, domain.sub_envs[i].MinY, 0 );
        OGR_G_CloseRings( hRing );
        OGR_G_AddGeometry( hPoly, hRing );
        OGR_L_ResetReading( hLayer );
        OGR_L_SetSpatialFilter( hLayer, hPoly );
        j = 0;
        while( (hFeat = OGR_L_GetNextFeature( hLayer )) != NULL )
        {
            if( j >= alloced )
            {
                alloced = alloced * 1.5;
                set[i].p = realloc( set[i].p, sizeof( bcal_point ) * alloced );
            }
            set[i].p[j].fid = OGR_F_GetFID( hFeat );
            set[i].p[j].c =
                OGR_F_GetFieldAsInteger( hFeat, OGR_F_GetFieldIndex( hFeat, "classification" ) );
            hGeom = OGR_F_GetGeometryRef( hFeat );
            set[i].p[j].x = OGR_G_GetX( hGeom, 0 );
            set[i].p[j].y = OGR_G_GetY( hGeom, 0 );
            set[i].p[j].z = OGR_G_GetZ( hGeom, 0 );
            OGR_F_Destroy( hFeat );
            j++;
        }
        /* Free unused array stuff */
        set[i].p = realloc( set[i].p, sizeof( bcal_point ) * (j - 1) );
        set[i].n = j - 1;
        OGR_L_SetSpatialFilter( hLayer, NULL );
        OGR_G_DestroyGeometry( hRing );
        OGR_G_DestroyGeometry( hPoly );
    }
    /* Thread over this loop */
    for( i = 0; i < domain.n; i++ )
    {
        //bin( points[i], p_counts[i], b->spacing );
        //set_init_ground(
    }
    for( i = 0; i < domain.n; i++ )
    {
        free( set[i].p );
        set[i].p = NULL;
    }
    free( set );
    set = NULL;

    GDALClose( hDS );
    return CE_None;
}

