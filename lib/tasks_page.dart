import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chopper/chopper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intermax_task_manager/Location%20Service/location_service.dart';
import 'package:intermax_task_manager/Stopwatch/stopwatch.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intermax_task_manager/Brigades%20Settings/brigades_settings.dart';
import 'package:intermax_task_manager/ServerSideApi/server_side_api.dart';
import 'package:intermax_task_manager/Tasks%20Settings/task_server_model.dart';
import 'package:intermax_task_manager/Tasks%20Settings/tasks_settings.dart';
import 'package:intermax_task_manager/User%20State/user_state.dart';
import 'package:intermax_task_manager/main.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:translit/translit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 1,
          channelKey: 'high_importance_channel',
          wakeUpScreen: true,
          displayOnBackground: true,
          backgroundColor: Colors.purpleAccent,
          displayOnForeground: true,
          title: '${message.notification!.title}',
          body: '${message.notification!.body}'
      )
  );
}

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {

  WebSocketChannel? _webSocketChannel;
  LocationService? _locationService;


  String? onWayHoursStr = '00';
  String? onWayMinutesStr = '00';
  String? onWaySecondsStr = '00';

  String? workStartedHoursStr = '00';
  String? workStartedMinutesStr = '00';
  String? workStartedSecondsStr = '00';

  String? allTaskTimeHours = '00';
  String? allTaskTimeMinutes = '00';
  String? allTaskTimeSeconds = '00';

  String? onWayTime = '00:00:00';
  String? workTime = '00:00:00';

  StateSetter? statusState;
  StateSetter? brigadesTaskState;
  StateSetter? taskInfoState;
  StateSetter? mapTaskInfoState;
  StateSetter? mapState;

  int? _bottomNavBarItemIndex = 0;

  double? lat;
  double? long;

  FocusNode? _ipAddressFocusNode;
  FocusNode? _nameFocusNode;
  FocusNode? _passwordFocusNode;
  FocusNode? _tasksFocusNode;

  List<TaskServerModel>? _brigadeTaskList;

  Stream<int>? onWayTimerStream;
  Stream<int>? workStartedTimerStream;

  StreamSubscription<int>? onWayTimerSubscription;
  StreamSubscription<int>? workStartedTimerSubscription;

  StopWatch? stopWatch;

  var dateFormatter = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    Tasks.initPreferences();
    Brigades.initPreferences();

    stopWatch = StopWatch.init();

    _tasksFocusNode = FocusNode();
    _ipAddressFocusNode = FocusNode();
    _nameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.instance.subscribeToTopic(Translit().toTranslit(source: UserState.getBrigade()!));
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: 2,
              wakeUpScreen: true,
              displayOnBackground: true,
              backgroundColor: Colors.purpleAccent,
              color: Colors.purpleAccent,
              displayOnForeground: true,
              channelKey: 'high_importance_channel',
              title: '${message.notification!.title}',
              body: '${message.notification!.body}',
            )
        );
      }
    });

    _webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://192.168.0.38:8080'));
    _webSocketChannel!.stream.listen((event) {
      Map<String, dynamic> eventMap = json.decode(event);
      String? brigade = eventMap['brigade'];
      String? taskId = eventMap['id'];

      TaskServerModel? taskModel;
      for(var taskItem in _brigadeTaskList!) {
        if(taskId == taskItem.id){
          taskModel = taskItem;
          break;
        }
      }

      if(brigade == UserState.getBrigade()){
        eventMap.forEach((key, value) {
          switch (key) {
            case 'task':
              if (eventMap['task'] != null) {
                brigadesTaskState!(() {
                  taskModel!.task = eventMap['task'];
                });
              }
              break;
            case 'address':
              if (eventMap['address'] != null) {
                brigadesTaskState!(() {
                  taskModel!.address = eventMap['address'];
                });
              }
              break;
            case 'color':
              if (eventMap['color'] != null) {
                brigadesTaskState!(() {
                  taskModel!.color = eventMap['color'];
                });
              }
              break;
            case 'date':
              if (eventMap['date'] != null) {
                brigadesTaskState!(() {
                  taskModel!.date = eventMap['date'];
                });
              }
              break;
            case 'time':
              if (eventMap['time'] != null) {
                brigadesTaskState!(() {
                  taskModel!.time = eventMap['time'];
                });
              }
              break;
            case 'note1':
              if (eventMap['note1'] != null) {
                brigadesTaskState!(() {
                  taskModel!.note1 = eventMap['note1'];
                });
              }
              break;
            case 'note2':
              if (eventMap['note2'] != null) {
                brigadesTaskState!(() {
                  taskModel!.note2 = eventMap['note2'];
                });
              }
              break;
            case 'telephone':
              if(eventMap['telephone'] != null){
                taskModel!.telephone = eventMap['telephone'];
              }
              break;
            case 'urgent':
              if(eventMap['urgent'] != null){
                taskModel!.isUrgent = eventMap['urgent'].toString();
              }
          }
        });

        switch (eventMap['status']) {
          case 'Не выполнено':
            setState(() {
              _bottomNavBarItemIndex = 0;
            });
            break;
          case 'В пути':
            setState(() {
              _bottomNavBarItemIndex = 1;
            });
            break;
          case 'На месте':
            setState(() {
              _bottomNavBarItemIndex = 1;
            });
            break;
          case 'Завершено':
            setState(() {
              _bottomNavBarItemIndex = 2;
            });
            break;
        }
      }
    });
    // _locationService = LocationService.init(_webSocketChannel!);
    // _locationService!.checkLocationPermission();
    // _locationService!.getLocationChanges();
  }

  @override
  void dispose() {
    super.dispose();

    _ipAddressFocusNode!.dispose();
    _nameFocusNode!.dispose();
    _passwordFocusNode!.dispose();
    _tasksFocusNode!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper.builder(
      Scaffold(
          appBar: AppBar(
            title: const Text(
                'Планировщик задач Intermax', style: TextStyle(fontSize: 25)),
            centerTitle: false,
            backgroundColor: Colors.deepOrangeAccent,
            automaticallyImplyLeading: false,
          ),
          bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              iconSize: 30,
              elevation: 20.0,
              currentIndex: _bottomNavBarItemIndex!,
              selectedItemColor: Colors.deepOrangeAccent,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                    label: 'Новые задачи',
                    icon: Icon(Icons.upcoming_rounded)
                ),
                BottomNavigationBarItem(
                    label: 'Текущие задачи',
                    icon: Icon(Icons.task_rounded)
                ),
                BottomNavigationBarItem(
                    label: 'Завершённые задачи',
                    icon: Icon(Icons.done)
                ),
                BottomNavigationBarItem(
                    label: 'Выйти',
                    icon: Icon(Icons.logout)
                )
              ],
              onTap: (index) {
                if (index == 0) {
                  setState(() {
                    _bottomNavBarItemIndex = index;
                  });
                } else if (index == 1) {
                  setState(() {
                    _bottomNavBarItemIndex = index;
                  });
                } else if (index == 2) {
                  setState(() {
                    _bottomNavBarItemIndex = index;
                  });
                } else if (index == 3) {
                  _showSignOutDialog();
                }
              },
            ),
          body: getBrigadeTasks(_bottomNavBarItemIndex!)
      ),
      breakpoints: const [
        ResponsiveBreakpoint.resize(500, name: MOBILE),
        ResponsiveBreakpoint.resize(800, name: TABLET),
        ResponsiveBreakpoint.resize(1000, name: DESKTOP),
      ],
      defaultScale: true,
    );
  }

  // Getting tasks from server (Android version)
  FutureBuilder<Response<List<TaskServerModel>>> getBrigadeTasks(int index) {
    String? status;
    switch (index) {
      case 0:
        status = 'Не выполнено';
        break;
      case 1:
        status = 'В пути';
        break;
      case 2:
        status = 'Завершено';
        break;
    }
    var data = {
      'ip': '192.168.0.38',
      'brigade': UserState.getBrigade(),
      'status': status
    };

    return FutureBuilder<Response<List<TaskServerModel>>>(
      future: ServerSideApi.create('192.168.0.38', 3).getBrigadeTask(data),
      builder: (context, snapshot) {
        while (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.deepOrangeAccent,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          _brigadeTaskList = snapshot.data!.body;
          return buildTaskForBrigade(_brigadeTaskList);
        } else {
          return const Center(
            child: Text('Список задач пуст', style: TextStyle(fontSize: 20)),
          );
        }
      },
    );
  }

  // Building tasks table for specific brigade(Android version)
  Widget buildTaskForBrigade(List<TaskServerModel>? _brigadeTaskList) {
    return ListView.builder(
      itemCount: _brigadeTaskList!.length,
      itemBuilder: (context, index) {
        TaskServerModel brigadeTask = _brigadeTaskList[index];
        String? formattedDate = dateFormatter.format(DateTime.now());

        if (formattedDate == brigadeTask.date) {
          brigadeTask.date = "Сегодня";
        }

        return StatefulBuilder(
          builder: (context, setState) {
            brigadesTaskState = setState;
            return GestureDetector(
                child: Card(
                    elevation: 5,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(brigadeTask.task, style: TextStyle(
                                color: Color(int.parse('0x' + brigadeTask.color)),
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                            trailing: _bottomNavBarItemIndex == 0
                                ? Text(brigadeTask.status, style: const TextStyle(color: Colors.red, fontSize: 18)) :_bottomNavBarItemIndex == 1
                                ? Text(brigadeTask.status,
                                style: TextStyle(color: brigadeTask.status == 'В пути' ? Colors.orangeAccent[700] : Colors.yellow[700], fontSize: 18)) : _bottomNavBarItemIndex == 2
                                ? Text(brigadeTask.status, style: const TextStyle(color: Colors.green, fontSize: 18)) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(brigadeTask.date + " в " + brigadeTask.time,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 3),
                                Text(brigadeTask.address!,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 5),
                                brigadeTask.note1 != '' || brigadeTask.note2 != '' ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Примечание', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                                  ],
                                ) : Container(),
                                brigadeTask.note1 != '' ? Text(brigadeTask.note1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Container(),
                                brigadeTask.note2 != '' ? Text(brigadeTask.note2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Container(),
                                const SizedBox(height: 5)
                              ],
                            ),
                          )
                        ]
                    )
                ),
                onTap: () {
                  showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, dialogState) {
                        taskInfoState = dialogState;
                        return SizedBox(
                          child: SimpleDialog(
                            title: const Text(
                              'Детали о задаче',
                              style: TextStyle(color: Colors.black, fontSize: 30),
                            ),
                            contentPadding: const EdgeInsets.only(
                                left: 5, right: 5, bottom: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0)),
                            backgroundColor: Colors.white,
                            children: [
                              const SizedBox(height: 5),
                              Center(
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        brigadeTask.task,
                                        style: TextStyle(color: Color(
                                            int.parse('0x' + brigadeTask.color))),
                                      ),
                                      leading: const Icon(Icons.task),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      title: Text(brigadeTask.address),
                                      leading: const Icon(
                                          Icons.add_location_rounded),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      title: Text(brigadeTask.telephone),
                                      leading: const Icon(Icons.phone),
                                      onTap: () {
                                        launch('tel://${brigadeTask.telephone!}');
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                        title: Text(brigadeTask.isUrgent == '1'
                                            ? "Срочно"
                                            : "Не срочно"),
                                        leading: const Icon(
                                            Icons.access_time_outlined)
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 300,
                                      child: FloatingActionButton.extended(
                                          label: Center(
                                            child: Column(
                                              children: [
                                                const Text('В пути'),
                                                const SizedBox(height: 0.5),
                                                Text(brigadeTask.status != 'Завершено' ? "$onWayHoursStr:$onWayMinutesStr:$onWaySecondsStr" : brigadeTask.onWayTime)
                                              ],
                                            ),
                                          ),
                                          backgroundColor: brigadeTask.status == 'Не выполнено'
                                              ? Colors.orangeAccent[700]
                                              : Colors.grey,
                                          onPressed: brigadeTask.status == 'Не выполнено'
                                              ? () async {
                                            var data = {
                                              'ip': '192.168.0.38',
                                              'id': brigadeTask.id,
                                              'status': 'В пути'
                                            };
                                            Response response = await ServerSideApi.create('192.168.0.38', 1).updateStatus(data);

                                            var socketData = {
                                              'id' : brigadeTask.id,
                                              'status' : 'В пути'
                                            };

                                            _webSocketChannel!.sink.add(json.encode(socketData));

                                            if (response.body == 'status_updated') {
                                              Navigator.pop(context);
                                              setState(() {});
                                            }

                                            onWayTimerStream = stopWatch!.onWayStopWatchStream();
                                            onWayTimerSubscription = onWayTimerStream!.listen((tick) {
                                              taskInfoState!(() {
                                                onWayHoursStr = ((tick / (60 * 60)) % 60).floor().toString().padLeft(2, '0');
                                                onWayMinutesStr = ((tick / 60) % 60).floor().toString().padLeft(2, '0');
                                                onWaySecondsStr = (tick % 60).floor().toString().padLeft(2, '0');
                                              });
                                            });
                                          } : null
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 300,
                                      child: FloatingActionButton.extended(
                                        label: Center(
                                          child: Column(
                                            children: [
                                              const Text('На месте'),
                                              const SizedBox(height: 0.5),
                                              Text(brigadeTask.status != 'Завершено' ? "$workStartedHoursStr:$workStartedMinutesStr:$workStartedSecondsStr" : brigadeTask.workTime)
                                            ],
                                          ),
                                        ),
                                        backgroundColor: brigadeTask.status == 'В пути'
                                            ? Colors.yellow[700]
                                            : Colors.grey,
                                        onPressed: brigadeTask.status == 'В пути' ? () async {

                                          var data = {
                                            'ip': '192.168.0.38',
                                            'id': brigadeTask.id,
                                            'status': 'На месте'
                                          };

                                          var timeData = {
                                            'ip' : '192.168.0.38',
                                            'id' : brigadeTask.id,
                                            'on_way_time' : '$onWayHoursStr:$onWayMinutesStr:$onWaySecondsStr',
                                          };

                                          Response response = await ServerSideApi.create('192.168.0.38', 1).updateStatus(data).whenComplete(() async {
                                            await ServerSideApi.create('192.168.0.38', 1).updateOnWayTime(timeData);
                                          });

                                          var socketData = {
                                            'id' : brigadeTask.id,
                                            'status' : 'На месте',
                                            'onWayTime' : '$onWayHoursStr:$onWayMinutesStr:$onWaySecondsStr'
                                          };

                                          _webSocketChannel!.sink.add(json.encode(socketData));

                                          if (response.body == 'status_updated') {
                                            Navigator.pop(context);
                                            setState(() {});
                                          }

                                          onWayTimerSubscription!.cancel();
                                          onWayTimerStream = null;

                                          workStartedTimerStream = stopWatch!.workStartedStopWatchStream();
                                          workStartedTimerSubscription = workStartedTimerStream!.listen((tick) {
                                            taskInfoState!(() {
                                              workStartedHoursStr = ((tick / (60 * 60)) % 60).floor().toString().padLeft(2, '0');
                                              workStartedMinutesStr = ((tick / 60) % 60).floor().toString().padLeft(2, '0');
                                              workStartedSecondsStr = (tick % 60).floor().toString().padLeft(2, '0');
                                            });
                                          });
                                        } : null,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 300,
                                      child: FloatingActionButton.extended(
                                          label: Center(
                                            child: Column(
                                              children: [
                                                const Text('Завершено'),
                                                const SizedBox(height: 0.5),
                                                Text(brigadeTask.allTaskTime)
                                              ],
                                            ),
                                          ),
                                          backgroundColor: brigadeTask.status == 'На месте'
                                              ? Colors.green[700]
                                              : brigadeTask.status == 'Завершено' ? Colors.grey : Colors.grey,
                                          onPressed: brigadeTask.status == 'На месте'
                                              ? () async {

                                            allTaskTimeSeconds = (int.parse(onWaySecondsStr!) + int.parse(workStartedSecondsStr!)).floor().toString().padLeft(2, '0');
                                            allTaskTimeMinutes = (int.parse(onWayMinutesStr!) + int.parse(workStartedMinutesStr!)).floor().toString().padLeft(2, '0');
                                            allTaskTimeHours = (int.parse(onWayHoursStr!) + int.parse(workStartedHoursStr!)).floor().toString().padLeft(2, '0');

                                            if(int.parse(allTaskTimeSeconds!) >= 60){
                                              allTaskTimeSeconds = (int.parse(allTaskTimeSeconds!) - 60).floor().toString().padLeft(2, '0');
                                              allTaskTimeMinutes = (int.parse(allTaskTimeMinutes!) + 1).floor().toString().padLeft(2, '0');
                                            }

                                            if(int.parse(allTaskTimeMinutes!) >= 60){
                                              allTaskTimeMinutes = (int.parse(allTaskTimeMinutes!) - 60).floor().toString().padLeft(2, '0');
                                              allTaskTimeHours = (int.parse(allTaskTimeHours!) + 1).floor().toString().padLeft(2, '0');
                                            }

                                            String allTaskTimeStr = '$allTaskTimeHours:$allTaskTimeMinutes:$allTaskTimeSeconds';

                                            var data = {
                                              'ip': '192.168.0.38',
                                              'id': brigadeTask.id,
                                              'status': 'Завершено'
                                            };

                                            var timeData = {
                                              'ip': '192.168.0.38',
                                              'id': brigadeTask.id,
                                              'work_time' : '$workStartedHoursStr:$workStartedMinutesStr:$workStartedSecondsStr',
                                              'all_task_time' : allTaskTimeStr
                                            };

                                            Response response = await ServerSideApi.create('192.168.0.38', 1).updateStatus(data).whenComplete(() async {
                                              await ServerSideApi.create('192.168.0.38', 1).updateWorkTime(timeData);
                                            });


                                            var socketData = {
                                              'id' : brigadeTask.id,
                                              'status' : 'Завершено',
                                              'workTime' : '$workStartedHoursStr:$workStartedMinutesStr:$workStartedSecondsStr',
                                              'allTaskTime' : allTaskTimeStr
                                            };

                                            _webSocketChannel!.sink.add(json.encode(socketData));

                                            if (response.body ==
                                                'status_updated') {
                                              Navigator.pop(context);
                                              setState(() {});
                                            }

                                            workStartedTimerSubscription!.cancel();
                                            workStartedTimerStream = null;
                                          } : null
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 300,
                                      child: FloatingActionButton.extended(
                                        label: const Text('Закрыть'),
                                        backgroundColor: Colors.blue,
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  }
              );
            },
            );
          }
        );
      },
    );
  }

  // Showing sign out dialog
  void _showSignOutDialog() {
    Widget _signOutButton = TextButton(
      child: const Text(
        'Выйти',
        style: TextStyle(color: Colors.redAccent),
      ),
      onPressed: () {
        UserState.rememberUserState(false);
        UserState.clearBrigade();
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskManagerMainPage()));

        FirebaseMessaging.instance.unsubscribeFromTopic(Translit().toTranslit(source: UserState.getBrigade()!));
      },
    );

    Widget _cancelButton = TextButton(
        child: const Text(
            'Отмена', style: TextStyle(color: Colors.deepOrangeAccent)),
        onPressed: () {
          Navigator.pop(context);
          _webSocketChannel!.sink.close();
        });

    AlertDialog dialog = AlertDialog(
        title: const Text('Выйти из аккаунта'),
        content: const Text('Вы действительно хотите выйти ?'),
        actions: [_cancelButton, _signOutButton]);

    showDialog(
        context: context,
        builder: (context) {
          return dialog;
        });
  }

}