percentString = (x)->
	(x*100).toFixed(1)+"%"


findClosest = (x,y)->
  closest = null
  closestDist = 100000
  # console.log("finding closest", x,y)
  for d in visibleCells
    if d.data.RPSS > 0
      dist = Math.pow(x-d.point.x, 2)+Math.pow(y-d.point.y,2)
      if dist < closestDist
        closest = d
        closestDist = dist

  return closest

normalizeLon = (x)->
  x +=360 while x < -180
  x -=360 while x > 180
  x

normalizeLat = (x)->
  x +=180 while x < -90
  x -=180 while x > 90
  x



getCellsInBounds = (b)->
  result = []

  bx1 = b.getWest()
  bx2 = b.getEast()
  bxDiff = Math.abs(b.getWest() - b.getEast())

  # detect how often we've wrapped the map around already
  bxOffsetWest = bxOffsetEast = 0
  if bx1 < -180
    bxTemp = bx1
    while bxTemp < -180
      bxTemp += 360
      bxOffsetWest -= 360
  else if bx1 > 180
    bxTemp = bx1
    while bxTemp > 180
      bxTemp -= 360
      bxOffsetWest += 360
  if bx2 < -180
    bxTemp = bx2
    while bxTemp < -180
      bxTemp += 360
      bxOffsetEast -= 360
  else if bx2 > 180
    bxTemp = bx2
    while bxTemp > 180
      bxTemp -= 360
      bxOffsetEast += 360

  by1 = normalizeLat b.getNorth()
  by2 = normalizeLat b.getSouth()

  # console.log "-----------------------","getCellsInBounds", bx1, bx2, bxOffsetWest, bxOffsetEast, bxDiff

  for slice in cellSlices
    _lon = slice[0]?.lon
    if (Math.abs(_lon + bxOffsetEast - bx1) < bxDiff or Math.abs(_lon + bxOffsetWest - bx1) < bxDiff) and (Math.abs(_lon + bxOffsetWest - bx2) < bxDiff or Math.abs(_lon + bxOffsetEast - bx2) < bxDiff)
      # fits
    else
      continue

    for cell in slice
      if cell.lat < by2
        continue
      if cell.lat > by1
        break
      # debugger
      _point = map.latLngToContainerPoint(cell.loc)
      while _point.x > 4096
        _point.x -= 4096
      while _point.x < 0
        _point.x += 4096

      #console.log _cellLoc
      result.push(
        point: _point
        data: cell
      )

  return result
