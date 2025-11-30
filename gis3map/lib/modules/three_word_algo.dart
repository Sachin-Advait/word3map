
// Simple projection: lat/lon -> meters (approx)
Map<String, double> latLonToMeters(double lat, double lon) {
  double x = lon * 111320.0; // approx meters per degree longitude at equator
  double y = lat * 110540.0; // approx meters per degree latitude
  return {"x": x, "y": y};
}

String latLonToThreeWords(double lat, double lon, List<String> wordlist) {
  lat = lat.clamp(-90.0, 90.0);
  lon = lon.clamp(-180.0, 180.0);

  int wLen = wordlist.length;

  // Simple direct mapping
  int latIndex = ((lat + 90.0) / 180.0 * (wLen - 1)).round().clamp(0, wLen - 1);
  int lonIndex = ((lon + 180.0) / 360.0 * (wLen - 1)).round().clamp(
    0,
    wLen - 1,
  );

  // Use a simple combination for the third word
  int thirdIndex = (latIndex + lonIndex * 7) % wLen;

  return "${wordlist[latIndex]}.${wordlist[lonIndex]}.${wordlist[thirdIndex]}";
}

Map<String, double> threeWordsToLatLon(String code, List<String> wordlist) {
  List<String> words = code.split('.');
  if (words.length != 3) return {"lat": 0.0, "lon": 0.0};

  int wLen = wordlist.length;

  int latIndex = wordlist.indexOf(words[0]);
  int lonIndex = wordlist.indexOf(words[1]);

  if (latIndex == -1 || lonIndex == -1) return {"lat": 0.0, "lon": 0.0};

  // Convert back to coordinates
  double lat = (latIndex / (wLen - 1)) * 180.0 - 90.0;
  double lon = (lonIndex / (wLen - 1)) * 360.0 - 180.0;

  return {"lat": lat, "lon": lon};
}
