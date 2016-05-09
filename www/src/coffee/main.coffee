"""
Project Ukko
https://github.com/MoritzStefaner/project-ukko-os
(c) by Moritz Stefaner and Dominikus Baur, 2015-2016

"""

svg = null
data = null
map = null
maxRPSS = 0
maxPower = 0
YEARS = [0,0]
cellSlices = []

SELECTION_COLOR = 0xFD6784

renderer = new PIXI.CanvasRenderer(document.body.clientWidth, document.body.clientHeight, {
  antialias: true
  transparent: true
  autoResize: true
  resolution: 1
})

stage = new PIXI.Container()
pixiGraphics = new PIXI.Graphics()
stage.interactive = false
stage.addChild(pixiGraphics)


visibleCells = []
selectedID = undefined


# colors

upCol = d3.hcl("#D9FF8A")
downCol = d3.hcl("#32dbe0")
grey = d3.interpolateLab((d3.interpolateLab(upCol, downCol)(.5)), "#FFF")(.5)
downScale = d3.interpolateLab(grey, downCol)
upScale = d3.interpolateLab(grey, upCol)

alphaScale = d3.scale.quantize().domain([0,.75]).range([0.25, 0.5, 0.75, 1])

$ ->
  # $.couch.info({
  #   success: (data) ->
  #     console.log(data)
  # })

  $(window).on "resize", ()->
    renderer.resize(document.body.clientWidth, document.body.clientHeight)
    scale = Math.min(1, document.body.clientWidth/1180)
    $("#details .container").css("zoom", (scale*100)+"%")
    $("#details").css("height", (scale*260))
    d3.select("#skill .help-spot").classed("jump-left", scale<1)


  $("body").addClass("loading")

  d3.json "data/config.json", (d)->
    window.CONFIG = d
    YEARS = [window.CONFIG.years[0]..window.CONFIG.years[1]]

    $("#prediction-start-date").html(d.predictionStartDate)
    $("#prediction-season").html(d.predictionSeason)
    $("#prediction-system").html(d.predictionSystem)

    d3.tsv "data/csv/globalstats.csv", (_d)->
      data = _d
      map = new mapboxgl.Map('map', "moritzstefaner.7ff13712", {
          center: [7.38, -69.61]#[50, 10]
          zoom: 5
          zoomControl: true
          minZoom: 4
          maxZoom: 6
          continuousWorld: true
          # maxBounds: L.latLngBounds(L.latLng(-90, -180), L.latLng(90, 180))
        })

      $("body").append $(".leaflet-control-container").detach()


      for d in data
        d.lat = normalizeLat +d.lat
        d.lon = normalizeLon +d.lon

        d.RPSS = +d.rpss
        d.meanHistoric = +d.meanHistoric
        d.meanPrediction = +d.meanPrediction
        if !d.lat
          console.log d
        d.loc = new mapboxgl.LatLng(d.lat, d.lon)

        d.ocean = d.ocean > 0

        cellSlices[+d.lonSlice] ?= []
        cellSlices[+d.lonSlice].push(d)

        if d.power
          maxPower = Math.max d.power, maxPower

      maxRPSS = d3.max((x.RPSS for x in data))

      $("body").removeClass("loading")

      console.log "data ready"
      init()
      render()

      map.on "render move zoomstart zoomend", _.throttle render, 50


init = ()->
  console.log "init" #, b, canvas.width, canvas.height
  initDetails()
  initLegend()
  d3.select("body").append("div.pixi").node().appendChild(renderer.view)
  initUI()
  readSettings()

# UI

startPos = {}
onDown = (x,y)->
  # console.log("down", x,y)
  startPos =
    x: x
    y: y
  startTime = (new Date()).getTime()
  hideMouseTip()

onMove = (x,y)->
  # console.log("move", x,y)
  closest = findClosest(x, y)
  if !closest?
    hideMouseTip()
    return

  diff = Math.sqrt((x-closest.point.x)*(x-closest.point.x) + (y-closest.point.y)*(y-closest.point.y))
  if(diff < 10)
    d3.select("#map").style("cursor", "pointer")
    showMouseTip("Click to see details about this region.", 1500, 5000)
  else
    d3.select("#map").style("cursor", "move")
    showMouseTip("The skill value is insufficient for a prediction in this area.", 1500, 5000)

onUp = (x,y)->
  # console.log("up", x,y)
  diff = Math.abs(startPos.x-x) + Math.abs(startPos.y-y)
  # console.log("diff", diff)
  if diff > 100
    return
  # console.log d3.event
  closest = findClosest(x, y)
  if !closest?
    hideMouseTip()
    return

  diff = Math.sqrt((x-closest.point.x)*(x-closest.point.x) + (y-closest.point.y)*(y-closest.point.y))
  if(diff >= 10)
    return

  selectedID = closest?.data.cellID
  hideMouseTip()
  render()

  jsonURL = "#{window.CONFIG.jsonPath}/#{closest.data.cellID}.json"
  d3.json(jsonURL, (error, data)->
    # console.log(error, data)
    if data?
      renderDetails(closest.data, closest.point, data)
    else
      console.warn("error loading data", jsonURL)
  ) if closest

d3.select("#map").on("mousedown", (d)->
  p = d3.event
  onDown(p.x || p.clientX, p.y || p.clientY)
)

lastTouchX = 0
lastTouchY = 0
d3.select("#map").on("touchstart", (d)->
  p = d3.event.touches[0]
  x = p.x || p.clientX
  y = p.y || p.clientY
  lastTouchX = x
  lastTouchY = y
  onDown(x,y)
)

d3.select("#map").on("mouseout", (d)->
  hideMouseTip()
)

d3.select("#map").on("mouseup", (d)->
  p = d3.event
  onUp(p.x || p.clientX, p.y || p.clientY)
)

d3.select("#map").on("touchend", (d)->
  onUp(lastTouchX, lastTouchY)
)

mouseTipInterval = null
d3.select("#map").on("mousemove", (d)->
  p = d3.event
  onMove(p.x || p.clientX, p.y || p.clientY)
)

d3.select("#map").on("touchmove", (d)->
  p = d3.event.touches[0]
  x = p.x || p.clientX
  y = p.y || p.clientY
  lastTouchX = x
  lastTouchY = y
  onMove(x, y)
)
# data mapping


initLegend = ()->

  _canvas2 = d3.selectAll(".map-legend div canvas").each((d, i)->
    _canvas = d3.select(@).node()
    legendRenderer = new PIXI.CanvasRenderer(60, 100, {
      antialias: true
      transparent: true
      view: _canvas
      resolution: 1
    })
    legendGraphics = new PIXI.Graphics()
    legendStage = new PIXI.Container()
    legendStage.interactive = false
    legendStage.addChild(legendGraphics)

    if(i == 0)
      y = 10
      steps = 4
      x = 10
      for i in [0..steps-1]
        renderGlyph legendGraphics, x-30, y+(steps-i-1)*20, .01+(i/(steps-1)) * maxRPSS, 0, 3, 50, true
    if(i==1)
      x = 20
      y = 20
      steps = 4
      for i in [0..steps]
        renderGlyph legendGraphics, x-5, y+(steps-i)*16-10, maxRPSS, 0, .5 + i*1.5, 15, true
    if(i==2)
      x = 13
      y = 23
      steps = 4
      for i in [0..steps]
        renderGlyph legendGraphics, x, y+(steps-1-i)*15, maxRPSS, .06*(i-steps/2), 4, 9
    if(i==3)
      x = 20
      y = 20
      steps = 2

      for i in [0..steps]
        yy = y+(steps-i)*26
        renderPower legendGraphics, x, yy, [200000, 500000, 1000000][i], 10

    legendRenderer.render(legendStage)

  )



d3.select("#details .close.button"). on "click", ()->
  selectedID = undefined
  renderDetails()
  render()
  false

oldBounds = undefined
boundsToString = (b)->
  "#{b.getWest()}, #{b.getSouth()}, #{b.getEast()}, #{b.getNorth()}"

currentlyHighContrast = false

render = ()->
  pixiGraphics.clear()

  b = map.getBounds()
  z = map.getZoom()

  if SETTINGS.high_contrast isnt currentlyHighContrast
    if SETTINGS.high_contrast
      op = .15
    else
      op = .6
    currentlyHighContrast = SETTINGS.high_contrast
    d3.select("#map-overlay-bg").transition().style("opacity", op)

  $("#start-year").text(window.CONFIG.years[0])
  $("#end-year").text(window.CONFIG.years[1])
  $("#prediction-time").text(window.CONFIG.predictionSeason)

  l = 450 * Math.pow(z/20, 3)

  if oldBounds isnt boundsToString b
    # console.time("get cells")
    visibleCells = getCellsInBounds(b)
    oldBounds = boundsToString b
    # console.log oldBounds
    # console.timeEnd("get cells")

  # console.time("drawing")


  for cell in visibleCells
    d = cell.data
    p = cell.point

    if d.cellID is selectedID
      pixiGraphics.moveTo(p.x, p.y)
      pixiGraphics.beginFill(SELECTION_COLOR, .5)
      pixiGraphics.drawCircle(p.x, p.y, l*2)
      pixiGraphics.endFill()

    if d.power > 0 and SETTINGS.show_windpower
      renderPower pixiGraphics, p.x, p.y, d.power, l

    change = Math.log(d.meanPrediction/d.meanHistoric)
    relRpss = Math.max(0, d.RPSS/maxRPSS) || 0
    strength = d.meanPrediction
    if !SETTINGS.mask_oceans or d.ocean
      renderGlyph pixiGraphics, p.x, p.y, relRpss, change, strength, l
    # console.log p.x, p.y
  renderer.render(stage)
  # console.timeEnd("drawing")
