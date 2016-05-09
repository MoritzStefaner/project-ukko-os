
historicSvg = undefined
predictionsSvg = undefined
yScale = undefined

W = 450
H = 200

yAxis = d3.svg.axis()
	.tickSize(-750)
	.ticks(4)
	.orient("left")
	.tickFormat(d3.format ".1f")

yAxisG = undefined

initDetails = ()->
	console.log "initDetails"
	historicContainer = d3.select("#details #historic .plot")

	historicSvg = historicContainer.append("svg").attr(
		width: W * 2
		height: H
	)

	yAxisG = historicSvg.append("g").classed("axis", true)
	.attr(
		"transform": "translate(28,0)"
	)
	.call(yAxis)

	historicSvg.append("rect.mid-range-marker").attr(
		"width": W-70
		"x": 32
	)

	predictionsContainer = d3.select("#details #predictions .plot")
	predictionsSvg = predictionsContainer.append("svg").attr(
		width: W
		height: H
	)

	# predictionsSvg.append("line.mean").attr(
	# 	"x2": W
	# )
	predictionsSvg.append("rect.mid-range-marker").attr(
		"width": 6
		"x": W-160
	)

	# predictionsSvg.append("text.mean").attr(
	# 	"x": W
	# )
	$("body").trigger("resize")


renderDetails = (selectedCell, point, detailData)->
	# console.log "render details"
	# console.log selectedCell, point, detailData
	# console.log selectedCell.lat, selectedCell.lon if selectedCell
	if !selectedCell
			$("#details").slideUp(300)
			d3.select(".leaflet-top").transition().style("margin-bottom", "0px").duration(300)
			return

	$("#details").slideDown(300)
	d3.select(".leaflet-top").transition().style("margin-bottom", "190px").duration(300)

	d3.select("#skill .number").text(percentString selectedCell.RPSS)
	d3.select("#skill .bar").style(
		"right": (1-selectedCell.RPSS)*100+"%"
	)

	d3.select("#power .number").text((d3.format("0,000")(selectedCell.power) || 0)+ " KW")

	predictions = detailData.predictions
	observations = detailData.observations
	allValues = predictions.concat observations

	xScale = d3.scale.linear().domain([0, observations.length-1]).range([40, W-60])
	yScale = d3.scale.linear().domain(d3.extent(allValues)).range([H-50, 20]).nice(4)

	yAxis.scale(yScale)
	yAxisG.transition().call(yAxis)

	els = historicSvg.selectAll(".dot").data(observations)

	mean = d3.median(observations)
	quantiles = d3.scale.quantile().domain(observations).range([0..2]).quantiles()

	els.enter().append("circle.dot")
		.translate((d, i)->
			[xScale(i), H]
		).attr(
			"r": 2.5
		)

	els.classed(
		"upper": (d)-> d>quantiles[1]
		"lower": (d)-> d<quantiles[0]
		"mid": (d)-> quantiles[1] >= d and d >= quantiles[0]
	).transition()
		.delay((d,i)->i*5)
		.translate((d, i)->
			[xScale(i), yScale(d)]
		)

	els.on "mouseover", (d, i)->
		showMouseTip "Seasonal average wind speed in #{YEARS[i]}: #{d.toFixed(1)} m/s"

	els.on "mouseout", (d)->
		hideMouseTip()

	meanY = yScale(mean)
	d3.select(".historic-mean").transition().style("bottom", H-meanY+30+"px")
	d3.select(".historic-mean span").text(mean.toFixed(1))

	rect = historicSvg.select("rect.mid-range-marker")
	rect.transition()
		.attr(
			"height": yScale(quantiles[0]) - yScale(quantiles[1])
			"y": yScale(quantiles[1])
			# "x": 0
	)

	text = historicSvg.select("text.mean")
	text.text(mean.toFixed(1))
	text.transition().translate([0,yScale(mean)-5])

	xScale = d3.scale.linear().domain([0, predictions.length]).range([W/2, W])
	# predictions.sort((a,b)-> a-b)

	els = predictionsSvg.selectAll(".dot").data(predictions)

	enter = els.enter().append("circle.dot")
		.translate((d, i)->
			[xScale(i), H]
		).attr(
			"r":2
		)

	els.on "mouseover", (d, i)->
		showMouseTip "Prediction number #{i+1} for #{window.CONFIG.predictionSeason}:<br/> #{d.toFixed(1)} m/s"

	els.on "mouseout", (d)->
		hideMouseTip()

	els.classed(
		"upper": (d)-> d>quantiles[1]
		"lower": (d)-> d<quantiles[0]
		"mid": (d)-> quantiles[1] >= d and d >= quantiles[0]
	)

	percentages = [
		(_.filter predictions, (d) -> d>quantiles[1]).length/predictions.length
		(_.filter predictions, (d) -> (quantiles[1] >= d and d >= quantiles[0])).length/predictions.length
		(_.filter predictions, (d) -> d<quantiles[0]).length/predictions.length
	]

	maxPercent = d3.max percentages

	d3.selectAll(".percentile").data(percentages)
	.classed(
		"most-probable": (d)-> d is maxPercent
	)
	.style(
		"opacity": (d)-> Math.max(.3, d*3)
	).select(".number").text((d)->
		percentString d
	)

	xPos = (d,i)->
		W - 290 + 80*Math.cos(Math.PI*((yScale(d)-meanY)/H))+i/2
		#W/1.5+(H/3)*Math.cos(Math.PI*((yScale(d)-meanY)/H))

	els.transition()
		.delay((d,i)->i*5)
		.translate((d, i)->
			[xPos(d,i), yScale(d)]
		)


	els = predictionsSvg.selectAll(".ray").data(predictions)
	enter = els.enter().append("line.ray")

	els.classed(
		"upper": (d)-> d>quantiles[1]
		"lower": (d)-> d<quantiles[0]
		"mid": (d)-> quantiles[1] >= d and d >= quantiles[0]
	)

	els.on "mouseover", (d, i)->
		showMouseTip "Prediction number #{i+1} for #{window.CONFIG.predictionSeason}:<br/> #{d.toFixed(1)} m/s"

	els.on "mouseout", (d)->
		hideMouseTip()

	els.transition()
		.attr(
			"x1": -20
			"y1": meanY
		).delay((d,i)->i*5)
		.attr(
			"x2": (d,i)-> xPos(d,i)
			"y2": (d,i)-> yScale(d)
		)

	rect = predictionsSvg.select("rect.mid-range-marker")
	rect.transition().attr(
			"height": yScale(quantiles[0]) - yScale(quantiles[1])
			"y": yScale(quantiles[1])
			# "x": 100
	)

	d3.selectAll(".percentiles").transition().style(
		"top": ((yScale(quantiles[1])+yScale(quantiles[0]))/2-39) + "px"
	)
