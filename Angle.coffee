define [], () ->

  DEG_COEF = 180 / Math.PI
  RAD_COEF = Math.PI / 180

  class Angle
    constructor: (value, unit = Angle.DEGREE) ->
      @value = if value is Angle.DEGREE then value else Angle.toDegrees( angle )

  Angle.toDegrees = (angle) ->
    angle * DEG_COEF

  Angle.toRadians = () ->
    angle * RAD_COEF

  Angle.RADIAN = 'radian'
  Angle.DEGREE = 'degree'

  return Angle