/*Function for Leaflet map*/

// function to set up the parameters of the leaflet map  
$scope.loadTheMap = function () {
	angular.extend($scope, {
		//default center of the map
		mapView: {
			lat: 45.6,
			lng: 9.9,
			zoom: 8
		},		
		// define the type of the map and the zoom level	
		layers: {
			baselayers: {
				osm: {
					name: 'OpenStreetMap',
					url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
					type: 'xyz',
					layerParams: {
						format: 'image/png',
						attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
					},
					layerOptions: {
						maxZoom: 21
					}
				}
			}
		},
		controls: {
			scale: {
				position: 'bottomright'
			}
		},
		markers: {
			
		}
	});
};

// Update the map with the current restaurant.
// The function takes in input the lat and the long of the current restaurant 
// The ma is centered in this point and a marker is added to identify the correct position of the restaurant
$scope.updateTheMap = function (latt, lngg) {
	var lat = parseFloat(latt);
	var lng = parseFloat(lngg);
	
	$scope.mapView.lat = lat;
	$scope.mapView.lng = lng;
	$scope.mapView.zoom = 18;
	
	$scope.markers = {
            "marker": {
                "lat": lat,
                "lng": lng,
                "focus": true,
                "draggable": false
            }
        }
	
};
