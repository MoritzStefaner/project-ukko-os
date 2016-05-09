defaultSettings = {
  mode: "trend"
  mask_oceans: false
  show_windpower: true
  high_contrast: false
}

validSettings = {
  mode: ["trend", "skill", "strength"]
  mask_oceans: [true, false]
  show_windpower: [true, false]
  high_contrast: [true, false]
}

SETTINGS = _.clone defaultSettings

window.onhashchange = ()->
  readSettings()

readSettings = () ->
  console.log("hashchange", document.location.hash)
  h = document.location.hash.replace("#", "").split("&")
  o = _.clone defaultSettings
  for [key, value] in (x.split("=") for x in h)
    value = true if value is "true"
    value = false if value is "false"
    o[key] = value if validSettings[key] and value in validSettings[key]
  SETTINGS = o
  onSettingsChanged()

onSettingsChanged = ()->
  updateUI()
  render()

initUI = ()->
  $(".collapsible h3").click(()->
    $(this).parent().toggleClass("collapsed")
  )
  $(".mode a").click(()->
    SETTINGS.mode = d3.select(@).attr("data-mode")
    updateHash(SETTINGS)
    false
  )

  d3.selectAll("input[type=checkbox]").on("change", ()->
    key = d3.select(@).attr("name")
    SETTINGS[key] = d3.select(@).property("checked")
    updateHash(SETTINGS)
    false
  )


  updateUI()

updateHash = ()->
  hash = []
  for key of SETTINGS
    value = SETTINGS[key]
    hash.push(key + "=" + value) if value isnt defaultSettings[key]
  hash = "#" + hash.join("&")
  # console.log(hash)
  document.location.hash = hash


updateUI = ()->
  d3.selectAll(".mode a").classed("selected", ()->
    # console.log d3.select(@).attr("data-mode"), SETTINGS.mode
    d3.select(@).attr("data-mode") is SETTINGS.mode
  )

  d3.selectAll("input[type=checkbox]").property("checked", ()->
    SETTINGS[d3.select(@).attr("name")]
  )

  d3.select("#windpower_legend").style("display", if SETTINGS.show_windpower then "block" else "none")

  d3.select("#change_legend").style("display", if SETTINGS.mode is "trend" then "block" else "none")
