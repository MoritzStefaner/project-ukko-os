tipContainer = d3.select(".mousetip")
tip = d3.select(".mousetip .tip")

hideID = null
showMouseTip = (text, delay = 0, hideDelay=0)->
	tip.html(text)
	tip.transition().style(
		"opacity": 1
		"visibility": "visible"
	).delay(delay)

	clearInterval(hideID)
	if hideDelay
		hideID = setTimeout(()->
			hideMouseTip()
		, hideDelay)

	d3.select("body").on "mousemove", (d)->
		m = d3.mouse(this)
		tipContainer.style(
			"left": m[0] + "px"
			"top": m[1] + "px"
		)

hideMouseTip = ()->
	clearInterval(hideID)
	tip.transition().style("opacity", 0)
	d3.select("body").on "mousemove", null
