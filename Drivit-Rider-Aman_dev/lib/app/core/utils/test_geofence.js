
function isInsideChennai(lat, lng) {
  const chennaiPolygon = [
    {lat: 12.824958370672775, lng: 80.2429907550401},
    {lat: 12.90394878589996, lng: 80.06652287419979},
    {lat: 12.984252441867923, lng: 80.10772160124424},
    {lat: 13.022387599307189, lng: 80.05828312879093},
    {lat: 13.23503347281619, lng: 80.15784671914828},
    {lat: 13.23302824185591, lng: 80.27114321852045},
    {lat: 13.269119871915699, lng: 80.29105593659193}

  ];

  let inside = false;
  for (let i = 0, j = chennaiPolygon.length - 1; i < chennaiPolygon.length; j = i++) {
    let xi = chennaiPolygon[i].lat, yi = chennaiPolygon[i].lng;
    let xj = chennaiPolygon[j].lat, yj = chennaiPolygon[j].lng;

    let intersect = ((yi > lng) !== (yj > lng)) &&
        (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

// Test cases
console.log("User Point (13.12, 80.23):", isInsideChennai(13.120469560715259, 80.23448467254639));
console.log("Central Chennai (13.08, 80.27):", isInsideChennai(13.08, 80.27));
console.log("T. Nagar (13.04, 80.23):", isInsideChennai(13.04, 80.23));
console.log("Adyar (13.00, 80.25):", isInsideChennai(13.00, 80.25));
console.log("Ambattur (13.11, 80.15):", isInsideChennai(13.11, 80.15));
console.log("Jaipur (26.91, 75.73):", isInsideChennai(26.91, 75.73));
