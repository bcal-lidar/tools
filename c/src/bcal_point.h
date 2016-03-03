// Copyright 2016 Boise State University.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef BCAL_POINT_H_
#define BCAL_POINT_H_

#include "bcal_types.h"

typedef struct bcal_point bcal_point;
struct bcal_point
{
    int64 fid;
    double x;
    double y;
    double z;
    uint8  c;
};

#endif /* BCAL_POINT_H_ */

