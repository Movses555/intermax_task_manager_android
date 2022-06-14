import 'package:chopper/chopper.dart';
import 'package:intermax_task_manager/Brigades%20Settings/brigade_details.dart';
import 'package:intermax_task_manager/JSON%20Converter/JsonToTypeConverter.dart';
import 'package:intermax_task_manager/Tasks%20Settings/task_server_model.dart';
import 'package:intermax_task_manager/User%20Details/user_details.dart';
import 'package:intermax_task_manager/host.dart';

part 'server_side_api.chopper.dart';

@ChopperApi()
abstract class ServerSideApi extends ChopperService{

  @Post(path: '/login_brigade.php')
  Future<Response<Brigade>> loginBrigade(@Body() var data);

  @Post(path: '/update_status.php')
  Future<Response> updateStatus(@Body() var data);

  @Post(path: '/update_brigade_status.php')
  Future<Response> updateBrigadeStatus(@Body() var data);

  @Post(path: '/get_brigade_tasks.php')
  Future<Response<List<TaskServerModel>>> getBrigadeTask(@Body() var data);

  @Post(path: '/get_brigade_tasks_history.php')
  Future<Response<List<TaskServerModel>>> getBrigadeTasksHistory(@Body() var data);


  static ServerSideApi create(String ip, int converterCode){
    JsonConverter? converter;

    switch(converterCode){
      case 1:
        converter = const JsonConverter();
        break;
      case 2:
        converter = JsonToTypeConverter({
          User: (json) => User.fromJson(json)
        });
        break;
      case 3:
        converter = JsonToTypeConverter({
          TaskServerModel: (json) => TaskServerModel.fromJson(json)
        });
        break;
      case 4:
        converter = JsonToTypeConverter({
          Brigade: (json) => Brigade.fromJson(json)
        });
        break;
    }

    final client = ChopperClient(
      baseUrl: 'http://${Host.ip}/Intermax Task Manager',
      services: [_$ServerSideApi()],
      converter: converter,
    );

    return _$ServerSideApi(client);
  }
}