define () ->
  class Point
    constructor : (x, y) ->
      @x = x
      @y = y

    distanceTo: (Point) ->
      dx = @x-Point.x
      dy = @y-Point.y
      Math.sqrt dx*dx + dy*dy