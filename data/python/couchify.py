import os
import sys
import numpy as np
import pupynere as netcdf
import csv
import math
import json

SAVE_TO_COUCH = False
SAVE_JSON = True

IN_FOLDER = "../netcdf/v4/"

if SAVE_TO_COUCH:
	import couchdb
	couch = couchdb.Server()

	couch.delete('euporias')
	db = couch.create('euporias')
	# db = couch['euporias']

output = csv.DictWriter(open("../csv/globalstats.csv", "w"), ["cellID","lat", "lon", "rpss", "meanPrediction", "meanHistoric", "power", "lonSlice", "ocean"], delimiter="\t")
output.writeheader()

outputPredictions = csv.DictWriter(open("../csv/predictions.csv", "w"), ["cellID","memberID", "windSpeed"], delimiter="\t")
outputPredictions.writeheader()

outputHistoric = csv.DictWriter(open("../csv/historic.csv", "w"), ["cellID","year","windSpeed"], delimiter="\t")
outputHistoric.writeheader()

windfarms = csv.DictReader(open("../csv/windfarms.csv", "r"), delimiter="\t")

#

skillsFile = netcdf.netcdf_file(IN_FOLDER + 'WindMod1DJF1leadGlobalSkill.nc', 'r')

print "skills file"
print skillsFile.variables

#


oceanMaskFile = netcdf.netcdf_file(IN_FOLDER + 'land_sea_mask_512x256.nc', 'r')

print "oceanMaskFile"
print oceanMaskFile.variables


#

forecastFile = netcdf.netcdf_file(IN_FOLDER + 'WindMod1DJF1leadGlobalForecast.nc', 'r')
print "forecast file"
print forecastFile.variables.keys()
print forecastFile.variables["forecast"].shape

#


historyFile = netcdf.netcdf_file(IN_FOLDER + 'WindObsDJF1leadGlobal.nc', 'r')
print "history file"
print historyFile.variables.keys()
print historyFile.variables["observations"].shape
#

count = 0
# years = range(1981,2011)
cells = []
cellDict = {}

def round(x):
	return float("%.2f" % x)

jsons = {}

skipped = 0
for (i,lat) in enumerate(skillsFile.variables["latitude"]):
	print i, lat
	for (j,lon) in enumerate(skillsFile.variables["longitude"]):
		# print j, lon
		if lon > 180:
			lon -= 360

		rpss = skillsFile.variables["RPSS"][i][j]
		ocean = oceanMaskFile.variables["tos"][-1][i][j]

		meanPrediction = 0
		meanHistoric = 0
		# print i,j
		predictions = []
		observations = []
		for (k,forecast) in enumerate(forecastFile.variables["forecast"][j][i]):

			outputPredictions.writerow({
				"cellID": count,
				"memberID": k,
				"windSpeed": float(forecast)
			})
			predictions += [float(forecast)]

		for (k,vals) in enumerate(historyFile.variables["observations"][j][i]):
			for (l,x) in enumerate(vals):
				outputHistoric.writerow({
					"cellID": count,
					"year": int(historyFile.variables["years"][l]),
					"windSpeed": float(x)
				})
				observations += [float(x)]

		id = str(count)
		jsons[id] = {
			"_id": id,
			"observations": observations,
			"predictions": predictions
		}

		cell = {
			"cellID": count,
			"lat": round(lat),
			"lon": round(lon),
			"rpss": round(rpss),
			"meanPrediction": round(np.median(predictions)),
			"meanHistoric": round(np.median(observations)),
			"power": 0,
			"ocean": ocean
		}

		cellDict[count] = cell
		cells += [cell]
		count += 1


print "counting farms"

try:
	cellForFarm = json.load(open("../csv/cellForFarm.json", "r"))
except:
	cellForFarm = {}
	outputJoin = csv.DictWriter(open("../csv/windCellJoin.csv", "w"), ["cellID","ID"], delimiter="\t")
	outputJoin.writeheader()

	for i,w in enumerate(windfarms):
		print "searching ", i
		try:
			lat = float(w['Latitude (WGS84)'])
			lon = float(w['Longitude (WGS84)'])
			closest = 0
			closestDist = 100000000
			for c in cells:
				dist = math.pow(float(c["lat"])-lat,2)+math.pow(float(c["lon"])-lon,2)
				if dist<closestDist:
					closestDist = dist
					closest = c
			cellForFarm[w["ID"]] = closest["cellID"]
			outputJoin.writerow({"cellID": closest["cellID"], "ID":w["ID"]})
		except:
			print "error", w

	json.dump(cellForFarm, open("../csv/cellForFarm.json", "w"))

for i,w in enumerate(windfarms):
	print "adding power ", i
	try:
		power = int(w["Total power (kW)"])
		print power, cellDict[cellForFarm[w["ID"]]]
		cellDict[cellForFarm[w["ID"]]]["power"] += power
	except:
		print "error", w["Total power (kW)"], w


print cells[0]
cells.sort(key = lambda x: (x["lon"],x["lat"]))

lonSlice = -1
currentLon = -9999

prunedCells = []
if SAVE_JSON:
	print "saving json"
	try:
		os.mkdir("../json/")
	except:
		pass

for c in cells:
	if c["power"] > 0 or c["rpss"]>0:
		if (c["lon"] != currentLon):
			currentLon = c["lon"]
			lonSlice += 1
		c["lonSlice"] = lonSlice
		prunedCells += [c]

		id = str(c["cellID"])
		o = jsons[id]

		if SAVE_TO_COUCH:
			db.save(o)
		if SAVE_JSON:
			json.dump(o, open("../json/"+id+".json", "w"))


print "%s cells kept, out of %s" % (len(prunedCells), len(cells))

output.writerows(prunedCells)