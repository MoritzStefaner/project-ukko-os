mapboxgl = L.mapbox
mapboxgl.LatLng = L.LatLng
mapboxgl.accessToken = 'pk.eyJ1IjoibW9yaXR6c3RlZmFuZXIiLCJhIjoiUGs4LU1VZyJ9.oJh_Gi3geralmUvrJVWYaA'

COUCH_URL = "https://starling.columba.uberspace.de/couchdb"
DB_NAME = "euporias"
$.couch.urlPrefix = COUCH_URL
DB = $.couch.db(DB_NAME)
