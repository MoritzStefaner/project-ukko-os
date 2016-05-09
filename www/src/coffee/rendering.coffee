getColor = (q) ->
  val = Math.max(0, Math.min(1, Math.abs(q)))
  col = if q > 0 then upScale(val) else downScale(val)
  return col.toString()

renderPower = (ctx, x, y, power, size)->
  s = Math.sqrt(power/maxPower) * size * 5

  offset = -Math.PI * (.5)
  TWO_PI = 2 * Math.PI
  angleWidth = .015 * TWO_PI

  alpha = Math.min(1, .5 + .8 * Math.sqrt(power/maxPower))
  ctx.moveTo(x, y)
  ctx.beginFill(0xFFFFFF)
  ctx.lineStyle(0)
  # ctx.arc(x, y, s, offset - TWO_PI*angleWidth, offset + TWO_PI*angleWidth)
  angle = offset
  ctx.lineTo(x+Math.cos(angle - angleWidth)*s, y+Math.sin(angle - angleWidth)*s)
  ctx.lineTo(x+Math.cos(angle + angleWidth)*s, y+Math.sin(angle + angleWidth)*s)
  ctx.moveTo(x, y)
  ctx.endFill()

  ctx.moveTo(x, y)
  ctx.beginFill(0xFFFFFF)
  ctx.lineStyle(0)
  angle = offset + .33*TWO_PI
  ctx.lineTo(x+Math.cos(angle - angleWidth)*s, y+Math.sin(angle - angleWidth)*s)
  ctx.lineTo(x+Math.cos(angle + angleWidth)*s, y+Math.sin(angle + angleWidth)*s)
  ctx.endFill()

  ctx.moveTo(x, y)
  ctx.beginFill(0xFFFFFF)
  ctx.lineStyle(0)
  angle = offset + .66*TWO_PI
  ctx.lineTo(x+Math.cos(angle - angleWidth)*s, y+Math.sin(angle - angleWidth)*s)
  ctx.lineTo(x+Math.cos(angle + angleWidth)*s, y+Math.sin(angle + angleWidth)*s)
  ctx.endFill()

  ctx.moveTo(x, y)
  ctx.beginFill(0xFFFFFF)
  ctx.lineStyle(s*.08, 0x333333)
  ctx.drawCircle(x, y, s*.15)
  ctx.endFill()


renderGlyph = (ctx, x, y, relRpss, change, strength, size, white = false)->

  if relRpss > 0
    alpha = alphaScale relRpss
  else
    return


  if SETTINGS.mode is "trend"
    color = parseInt(getColor(change*10).replace("#", "0x"))
    color = 0xFFFFFF if(white)
    angle = - change * 300
    angle = Math.min(45, angle)
    angle = Math.max(-45, angle)
    angle = Math.PI * angle/180
    # angle = 0
  else
    color = 0xFFFFFF
    angle = 0

  normalX = Math.cos(angle + Math.PI/2) * strength * size * .05
  normalY = Math.sin(angle + Math.PI/2) * strength * size * .05

  x1 = x - Math.cos(angle)*size
  y1 = y - Math.sin(angle)*size

  x2 = x + Math.cos(angle)*size
  y2 = y + Math.sin(angle)*size

  ctx.lineStyle(0)
  ctx.beginFill(color, alpha)

  ctx.moveTo(x1-normalX, y1-normalY)
  ctx.lineTo(x2-normalX, y2-normalY)
  ctx.lineTo(x2+normalX, y2+normalY)
  ctx.lineTo(x1+normalX, y1+normalY)

  ctx.endFill()


