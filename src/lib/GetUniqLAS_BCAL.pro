pro GetUniqLAS_BCAL, header, data

compile_opt idl2, logical_predicate

xMax = max(data.east,  min=xMin)
yMax = max(data.north, min=yMin)
zMin = min(data.elev)

eastRange  = ulong64(xMax - xMin)
northRange = ulong64(yMax - yMin)

uniqCoords = eastRange * northRange * (data.elev  - zMin) $
           + eastRange *              (data.north - yMin) $
           +                          (data.east  - xMin)

;uniqCoords = uniqCoords[sort(uniqCoords)]
;uniqCoords = uniq(uniqCoords)

uniqCoords = uniq(uniqCoords, sort(uniqCoords))

nUniq = n_elements(uniqCoords)

if nUniq ne header.nPoints then begin

    data = data[uniqCoords]

    header.nPoints = nUniq

endif


end