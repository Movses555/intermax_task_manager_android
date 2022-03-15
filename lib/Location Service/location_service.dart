import 'dart:convert';

import 'package:intermax_task_manager/Tasks%20Settings/task_server_model.dart';
import 'package:intermax_task_manager/User%20State/user_state.dart';
import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LocationService{

  static LocationService? instance;
  static WebSocketChannel? _socketChannel;
  static Stream? _broadcastStream;

  final Location _location = Location();

  LocationData? _locationData;

  static LocationService init(WebSocketChannel? webSocketChannel, Stream? broadcastStream){
    _socketChannel = webSocketChannel;
    _broadcastStream = broadcastStream;
    if(instance == null){
      instance = LocationService();
      return instance!;
    }else{
      return instance!;
    }
  }

  void checkLocationPermission() async {
    PermissionStatus? _permissionGranted;

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {

      }
    }
  }

  void checkLocationStatus() async {
    bool? _serviceEnabled;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _locationData = await _location.getLocation();
  }

  void getCurrentLocation() {

    double? lat = _locationData!.latitude;
    double? long = _locationData!.longitude;

    _broadcastStream!.listen((event) {
      Map<String, dynamic> map = json.decode(event);
      if(map['data'] == 'requesting_current_location' && map['brigade'] == UserState.getBrigade()){
        var data = {
          'data' : 'requesting_current_location',
          'lat' : lat,
          'long' : long,
        };

        _socketChannel!.sink.add(json.encode(data));
      }
    });
  }


  List<LocationData>? getLocationChanges() {
    List<LocationData>? locations;
    _location.onLocationChanged.listen((LocationData location) {

      locations!.add(location);

      var locationData = {
        'data' : 'location_updates',
        'brigade' : UserState.getBrigade(),
        'lat' : location.latitude,
        'long' : location.longitude
      };

      _socketChannel!.sink.add(json.encode(locationData));
    });

    return locations;
  }
}