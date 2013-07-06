define ['./Point'], (Point) ->

  # cached trig vars
  quarterCircle = -Math.PI / 2

  # basic functions
  _interpolateCubicBezier = (t, start, ctrl1, ctrl2, end) ->

    it = (1 - t)
    t2 = t * t
    t3 = t2 * t

    pt  =        start * it * it * it
    pt += 3 *    ctrl1 * it * it * t
    pt += 3 *    ctrl2 * it * t2
    pt +=          end * t3

  _subdivideCubicBezier = (t, start, ctrl1, ctrl2, end) ->
    splitPoint = _interpolateCubicBezier(t, start, ctrl1, ctrl2, end)

    # intermediate vars level 1
    outerA      = (1 - t) * start + t * ctrl1
    outerBridge = (1 - t) * ctrl1 + t * ctrl2
    outerB      = (1 - t) * ctrl2 + t * end

    # intermediate vars level 2
    innerA  = (1 - t) * outerA      + t * outerBridge
    innerB  = (1 - t) * outerBridge + t * outerB

    divided = {
      bezierA :
        start : start
        ctrl1 : outerA
        ctrl2 : innerA
        end   : splitPoint

      bezierB :
        start : splitPoint
        ctrl1 : innerB
        ctrl2 : outerB
        end   : end
    }

  _deriveCubicBezier = (t, start, ctrl1, ctrl2, end) ->
    dt  = 3 * (ctrl1 - start) * (1 - t) * (1 - t)
    dt += 3 * (ctrl2 - ctrl1) * 2 * t * (1 - t)
    dt += 3 * (end   - ctrl2) * t * t


  _mapValueToRange = (value, inputStart, inputEnd, outputStart, outputEnd) ->
    # Y = (X-A)/(B-A) * (D-C) + C
    (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart

  # classes
  class CubicBezier
    constructor : (start, ctrl1, ctrl2, end) ->
      @start = start
      @ctrl1 = ctrl1
      @ctrl2 = ctrl2
      @end = end

    interpolatePoint: (t) ->
      ptX = _interpolateCubicBezier(t, @start.x, @ctrl1.x, @ctrl2.x, @end.x)
      ptY = _interpolateCubicBezier(t, @start.y, @ctrl1.y, @ctrl2.y, @end.y)
      new Point(ptX, ptY)

    subdivide : (t, levels = 0) ->
      subX = _subdivideCubicBezier(t, @start.x, @ctrl1.x, @ctrl2.x, @end.x)
      subY = _subdivideCubicBezier(t, @start.y, @ctrl1.y, @ctrl2.y, @end.y)

      bezierA = new CubicBezier(
        new Point(subX.bezierA.start,  subY.bezierA.start)
        new Point(subX.bezierA.ctrl1,  subY.bezierA.ctrl1)
        new Point(subX.bezierA.ctrl2,  subY.bezierA.ctrl2)
        new Point(subX.bezierA.end,    subY.bezierA.end)
      )

      bezierB = new CubicBezier(
        new Point(subX.bezierB.start,  subY.bezierB.start)
        new Point(subX.bezierB.ctrl1,  subY.bezierB.ctrl1)
        new Point(subX.bezierB.ctrl2,  subY.bezierB.ctrl2)
        new Point(subX.bezierB.end,    subY.bezierB.end)
      )

      # recrusive sub div
      beziers = if (levels == 0) then [bezierA, bezierB] else bezierA.subdivide(t, levels-1).concat( bezierB.subdivide(t, levels-1))

    derive: (t) ->
      dtX = _deriveCubicBezier(t, @start.x, @ctrl1.x, @ctrl2.x, @end.x)
      dtY = _deriveCubicBezier(t, @start.y, @ctrl1.y, @ctrl2.y, @end.y)

      new Point( dtX, dtY)

    tangentVector: (t) ->
      dtX = _deriveCubicBezier(t, @start.x, @ctrl1.x, @ctrl2.x, @end.x)
      dtY = _deriveCubicBezier(t, @start.y, @ctrl1.y, @ctrl2.y, @end.y)

      d = Math.sqrt( dtX * dtX + dtY * dtY )

      nDtX = dtX / d
      nDtY = dtY / d

      new Point(nDtX, nDtY)

    normals: (t) ->
      {x: x, y: y} = @derive(t)

      newX = x * Math.cos( quarterCircle ) - y * Math.sin( quarterCircle )
      newY = x * Math.sin( quarterCircle ) + y * Math.cos( quarterCircle )

      new Point(newX, newY)

    normalVector: (t) ->
      {x: x, y: y} = @tangentVector(t)

      newX = x * Math.cos( quarterCircle ) - y * Math.sin( quarterCircle )
      newY = x * Math.sin( quarterCircle ) + y * Math.cos( quarterCircle )

      new Point(newX, newY)

    generateLUT: (resolution) ->
      lut = ( new Point(_interpolateCubicBezier(t, @start.x, @ctrl1.x, @ctrl2.x, @end.x), _interpolateCubicBezier(t, @start.y, @ctrl1.y, @ctrl2.y, @end.y)) for t in [0..1] by (1 / resolution))

    projectPoint: (point) ->
      @_lut ?= @generateLUT(20)
      px = point.x
      py = point.y
      lastDist = 800

      # 1. find position in LUT
      for tp, i in @_lut
        dist =  Math.sqrt (px-tp.x)*(px-tp.x) + (py-tp.y)*(py-tp.y)
        if dist > lastDist
          break
        else
          lastDist = dist

      # approx position
      aT = i / @_lut.length

    invalidate: ->
      @_lut = null

    toSVG : (curveOnly = false) ->
      unless isNaN(@start.x) or isNaN(@ctrl1.x) or isNaN(@ctrl2.x) or isNaN(@end.x)
        curve = "C#{@ctrl1.x},#{@ctrl1.y} #{@ctrl2.x},#{@ctrl2.y} #{@end.x},#{@end.y}"
        curve = if curveOnly then curve else "M#{@start.x},#{@start.y} "+curve
      else
        curve = null
      return curve