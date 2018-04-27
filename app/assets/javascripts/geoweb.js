/**
 * Custom GeoWeb modifications. This is included last.
 *
**/

GeoBlacklight.Basemaps['osmhot'] = L.tileLayer(
  'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
    maxZoom: 18,
    attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>'
  }
);

GeoBlacklight.Viewer.Map.mergeOptions({
  bbox: [[-45, -154], [65, 145]]
});
