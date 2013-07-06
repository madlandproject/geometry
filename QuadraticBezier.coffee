define ['./Point'], (Point) ->

  # cached trig vars
  quarterCircle = -Math.PI / 2

  class QuadraticBezier
    constructor: (start, ctrl, end) ->
      @start = start
      @ctrl = ctrl
      @end = end

    interpolatePoint: (t) ->
      ptx  = @start.x * (1 - t) * (1 - t)
      ptx += @ctrl.x * (1 - t) * t * 2
      ptx += @end.x * t * t

      pty  = @start.y * (1 - t) * (1 - t)
      pty += @ctrl.y * (1 - t) * t * 2
      pty += @end.y * t * t

      new Point(ptx, pty)

    derive : (t) ->
      dtx = 2 * (1-t) * (@ctrl.x - @start.x) + 2 * t * (@end.x - @ctrl.x)
      dty = 2 * (1-t) * (@ctrl.y - @start.y) + 2 * t * (@end.y - @ctrl.y)

      new Point(dtx, dty)

    tangentVector: (t) ->
      dt = @derive(t)
      d = Math.sqrt dt.x * dt.x + dt.y + dt.y

      new Point dt.x / d, dt.y / d

    normalVector: (t) ->
      vdt = @tangentVector(t)

      newX = vdt.x * Math.cos( quarterCircle ) - vdt.y * Math.sin( quarterCircle )
      newY = vdt.x * Math.sin( quarterCircle ) + vdt.y * Math.cos( quarterCircle )

      new Point(newX, newY)

    generateLUT: (resolution) ->
      @_lut = ( @interpolatePoint(t) for t in [0..1] by (1 / resolution))

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

    toSVG: (curveOnly = false) ->
      unless isNaN(@start.x) or isNaN(@ctrl.x) or isNaN(@end.x)
        curve = "Q#{@ctrl.x},#{@ctrl.y} #{@end.x},#{@end.y}"
        curve = if curveOnly then curve else "M#{@start.x},#{@start.y} "+curve
      else
        curve = null
      return curve