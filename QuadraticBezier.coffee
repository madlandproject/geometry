define ['./Point'], (Point) ->

  # cached trig vars
  quarterCircle = -Math.PI / 2

  class QuadraticBezier
    constructor: (start, ctrl, end) ->
      @start = start
      @ctrl = ctrl
      @end = end

    interpolatePoint: (t) ->
      it = (1 - t)
      ts = t * t

      ptx  = @start.x * it * it
      ptx += @ctrl.x * it * t * 2
      ptx += @end.x * ts

      pty  = @start.y * it * it
      pty += @ctrl.y * it * t * 2
      pty += @end.y * ts

      new Point(ptx, pty)

    derive : (t) ->
      it = (1 - t)

      dtx = 2 * it * (@ctrl.x - @start.x) + 2 * t * (@end.x - @ctrl.x)
      dty = 2 * it * (@ctrl.y - @start.y) + 2 * t * (@end.y - @ctrl.y)

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
      lut = ( @interpolatePoint(t) for t in [0..1] by (1 / resolution))

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