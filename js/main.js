var firebaseRef = new Firebase("https://blue-outsidehacks.firebaseio.com/geofire/");
var geoFire = new GeoFire(firebaseRef);

geoFire.set("test_key", [37.785326, -122.405696]).then(function() {
  console.log("Provided key has been added to GeoFire");
}, function(error) {
  console.log("Error: " + error);
});

var geoQuery = geoFire.query({
  center: [37.4, -122.6],
  radius: 1.609 //kilometers
});



