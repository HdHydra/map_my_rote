import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocationCache {
  late SharedPreferences _prefs;

  Future<Position> getLocation() async {
    // Check if cached location exists in shared preferences
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }

    final double? lat = _prefs.getDouble('lat');
    final double? lng = _prefs.getDouble('lng');
    final double? acc = _prefs.getDouble('acc');

    // If cached location exists and is not too old, return it
    if (lat != null && lng != null && acc != null) {
      final DateTime lastUpdate = DateTime.fromMillisecondsSinceEpoch(_prefs.getInt('last_update'));
      final Duration age = DateTime.now().difference(lastUpdate);
      if (age < const Duration(minutes: 5)) {
        return L(latitude: lat, longitude: lng, accuracy: acc);
      }
    }

    // If cached location is too old or doesn't exist, make new API call and cache result
    final Position position = await Geolocator.getCurrentPosition();
    _prefs.setDouble('lat', position.latitude);
    _prefs.setDouble('lng', position.longitude);
    _prefs.setDouble('acc', position.accuracy);
    _prefs.setInt('last_update', DateTime.now().millisecondsSinceEpoch);

    return position;
  }
}