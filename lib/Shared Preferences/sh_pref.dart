import 'package:shared_preferences/shared_preferences.dart';

class ShPref {

  static var _sharedPreferences;

  static Future<SharedPreferences> init() async {
    return _sharedPreferences = await SharedPreferences.getInstance();
  }

  static void setHasTask(bool hasTask){
    _sharedPreferences.setBool('has_task', hasTask);
  }

  static bool? getHasTask(){
    if(_sharedPreferences.getBool('has_task') == null){
      return false;
    }else{
      return _sharedPreferences.getBool('has_task');
    }
  }

}