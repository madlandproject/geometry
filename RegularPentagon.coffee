define ['./Point'], (Point) ->

  DEG2RAD = Math.PI / 180

  class RegularPentagon
    constructor: (radius, bias = 0) ->
      # draw first point straight down
      angles = (angle for angle in [0...360] by 72)
      @points = ( new Point( radius*Math.cos((angle+bias) * DEG2RAD), radius*Math.sin((angle+bias) * DEG2RAD)  ) for angle in angles )

    toSVG: () ->
      polygonData = ("#{point.x},#{point.y} " for point in @points).join('')