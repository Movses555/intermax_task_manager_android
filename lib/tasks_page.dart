import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chopper/chopper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intermax_task_manager/Flutter%20Toast/flutter_toast.dart';
import 'package:intermax_task_manager/Location%20Service/location_service.dart';
import 'package:intermax_task_manager/Shared%20Preferences/sh_pref.dart';
import 'package:intermax_task_manager/host.dart';
import 'package:location/location.dart';
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
}

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TaskPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver{


  var dateFormatter = DateFormat('dd.MM.yyyy');

  Stream? _socketBroadcastStream;
  WebSocketChannel? _webSocketChannel;
  LocationService? _locationService;

  StateSetter? taskState;
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
  List<TaskServerModel>? _brigadeTasksHistoryList;
  List<LocationData>? locations = [];

  ShowMessage? _showMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _showMessage = ShowMessage.init();
    _tasksFocusNode = FocusNode();
    _ipAddressFocusNode = FocusNode();
    _nameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    Tasks.initPreferences();
    Brigades.initPreferences();

    FirebaseMessaging.instance.getInitialMessage();
    if(UserState.getBrigade() == 'Эдо-Артур'){
      FirebaseMessaging.instance.subscribeToTopic('Edo-Artur');
    }else{
      FirebaseMessaging.instance.subscribeToTopic(Translit().toTranslit(source: UserState.getBrigade()!));
    }

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

    _webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://${Host.socketIP}'));
    _socketBroadcastStream = _webSocketChannel!.stream.asBroadcastStream();

    _locationService = LocationService.init(_webSocketChannel, _socketBroadcastStream);
    _locationService!.checkLocationPermission();
    _locationService!.checkLocationStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var data = {
        'brigade' : UserState.getBrigade(),
        'status' : 'Online'
      };

      await ServerSideApi.create(Host.ip, 1).updateBrigadeStatus(data);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state){
      case AppLifecycleState.resumed:
        _webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://${Host.socketIP}'));
        _socketBroadcastStream = _webSocketChannel!.stream.asBroadcastStream();
        break;
      case AppLifecycleState.inactive:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.paused:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
  }

  @override
  void dispose() {

    _webSocketChannel!.sink.close();

    _ipAddressFocusNode!.dispose();
    _nameFocusNode!.dispose();
    _passwordFocusNode!.dispose();
    _tasksFocusNode!.dispose();

    super.dispose();
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
              showSelectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                    label: 'Новые',
                    icon: Icon(Icons.upcoming_rounded)
                ),
                BottomNavigationBarItem(
                    label: 'Текущие',
                    icon: Icon(Icons.task_rounded)
                ),
                BottomNavigationBarItem(
                    label: 'Завершённые',
                    icon: Icon(Icons.done)
                ),
                BottomNavigationBarItem(
                    label: 'История',
                    icon: Icon(Icons.history)
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
                  setState(() {
                    _bottomNavBarItemIndex = index;
                  });
                } else if (index == 4) {
                  _showSignOutDialog();
                }
              },
            ),
          body: _bottomNavBarItemIndex != 3 ? getBrigadeTasks(_bottomNavBarItemIndex!) : getBrigadeTasksHistory()
      ),
      breakpoints: const [
        ResponsiveBreakpoint.resize(500, name: MOBILE),
        ResponsiveBreakpoint.resize(800, name: TABLET),
        ResponsiveBreakpoint.resize(1000, name: DESKTOP),
      ],
      defaultScale: true,
    );
  }

  // Getting tasks from server
  FutureBuilder<Response<List<TaskServerModel>>> getBrigadeTasks(int index) {

    String? status;
    String? formattedDate = dateFormatter.format(DateTime.now());

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
      'brigade': UserState.getBrigade(),
      'date' : formattedDate,
      'status': status
    };

    return FutureBuilder<Response<List<TaskServerModel>>>(
      future: ServerSideApi.create(Host.ip, 3).getBrigadeTask(data),
      builder: (context, snapshot) {
        while (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.deepOrangeAccent,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          print(snapshot.data!.bodyString);
          _brigadeTaskList = snapshot.data!.body;

          _brigadeTaskList!.sort((a,b) => (a.isUrgent.toString().compareTo(b.isUrgent.toString())));
          _brigadeTaskList = _brigadeTaskList!.reversed.toList();
          return buildTaskForBrigade(_brigadeTaskList);
        } else {
          _listenSocket(null);
          return const Center(
            child: Text('Список задач пуст', style: TextStyle(fontSize: 20)),
          );
        }
      },
    );
  }

  // Getting tasks history from server
  FutureBuilder<Response<List<TaskServerModel>>> getBrigadeTasksHistory(){
    var data = {
      'brigade' : UserState.getBrigade()
    };

    return FutureBuilder<Response<List<TaskServerModel>>>(
      future: ServerSideApi.create(Host.ip, 3).getBrigadeTasksHistory(data),
      builder: (context, snapshot){
        while (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.deepOrangeAccent,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          _brigadeTasksHistoryList = snapshot.data!.body;
          return buildTasksHistory(_brigadeTasksHistoryList);
        } else {
          return const Center(
            child: Text('Список пуст', style: TextStyle(fontSize: 20)),
          );
        }
      },
    );
  }

  // Building tasks table for specific brigade
  StatefulBuilder buildTaskForBrigade(List<TaskServerModel>? _brigadeTaskList) {
    return StatefulBuilder(
      builder: (context, brigadesTaskState){
        taskState = brigadesTaskState;
        return ListView.builder(
          itemCount: _brigadeTaskList!.length,
          itemBuilder: (context, index) {
            TaskServerModel brigadeTask = _brigadeTaskList[index];
            String? formattedDate = dateFormatter.format(DateTime.now());

            if (formattedDate == brigadeTask.date) {
              brigadeTask.date = "Сегодня";
            }

            _listenSocket(brigadeTask);


            return GestureDetector(
              child: Card(
                  elevation: 5,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(brigadeTask.task, style: TextStyle(
                                  color: Color(int.parse('0x' + brigadeTask.color)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                              Column(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      SizedBox(height: 20),
                                      _bottomNavBarItemIndex == 0
                                          ? Text(brigadeTask.status, style: const TextStyle(color: Colors.red, fontSize: 18)) :_bottomNavBarItemIndex == 1
                                          ? Text(brigadeTask.status,
                                          style: TextStyle(color: brigadeTask.status == 'В пути' ? Colors.orangeAccent[700] : Colors.yellow[700], fontSize: 18)) : _bottomNavBarItemIndex == 2
                                          ? Text(brigadeTask.status, style: const TextStyle(color: Colors.green, fontSize: 18)) : Container(),
                                      SizedBox(height: 10),
                                      Text(brigadeTask.time, style: TextStyle(color: Colors.grey))
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Container(
                            width: 260,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    brigadeTask.isUrgent == '1' ?
                                    Text('Срочно', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red))
                                        : Container()
                                  ],
                                ),
                                Text(brigadeTask.address!,
                                  style: const TextStyle(fontSize: 20),
                                ),
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
                                          launchUrl(Uri.parse('tel://${brigadeTask.telephone!}'));
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
                                            label: const Center(
                                              child: Text('В пути'),
                                            ),
                                            backgroundColor: brigadeTask.status == 'Не выполнено'
                                                ? Colors.orangeAccent[700]
                                                : Colors.grey,
                                            onPressed: brigadeTask.status == 'Не выполнено' ? () async {

                                              if(ShPref.getHasTask() == false){
                                                ShPref.setHasTask(true);

                                                var data = {
                                                  'ip': Host.ip,
                                                  'id': brigadeTask.id,
                                                  'cords' : '',
                                                  'status': 'В пути'
                                                };

                                                Response response = await ServerSideApi.create(Host.ip, 1).updateStatus(data);

                                                var socketData = {
                                                  'id' : brigadeTask.id,
                                                  'status' : 'В пути'
                                                };

                                                _webSocketChannel!.sink.add(json.encode(socketData));

                                                if (response.body == 'status_updated') {
                                                  Navigator.pop(context);
                                                  _bottomNavBarItemIndex = 1;
                                                  setState(() {});
                                                }
                                              }else{
                                                _showMessage!.show(context, 9);
                                              }
                                            } : null
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 300,
                                        child: FloatingActionButton.extended(
                                          label: const Center(
                                            child: Text('На месте'),
                                          ),
                                          backgroundColor: brigadeTask.status == 'В пути'
                                              ? Colors.yellow[700]
                                              : Colors.grey,
                                          onPressed: brigadeTask.status == 'В пути' ? () async {


                                            var data = {
                                              'ip': Host.ip,
                                              'id': brigadeTask.id,
                                              'cords': '',
                                              'status': 'На месте'
                                            };

                                            var socketData = {
                                              'id' : brigadeTask.id,
                                              'status' : 'На месте',
                                            };

                                            Response response = await ServerSideApi.create(Host.ip, 1).updateStatus(data).whenComplete(() async {
                                              _webSocketChannel!.sink.add(json.encode(socketData));
                                            });


                                            if (response.body == 'status_updated') {
                                              Navigator.pop(context);
                                              _bottomNavBarItemIndex = 1;
                                              setState(() {});
                                            }
                                          } : null,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 300,
                                        child: FloatingActionButton.extended(
                                            label: const Center(
                                              child: Text('Завершено'),
                                            ),
                                            backgroundColor: brigadeTask.status == 'На месте'
                                                ? Colors.green[700]
                                                : brigadeTask.status == 'Завершено' ? Colors.grey : Colors.grey,
                                            onPressed: brigadeTask.status == 'На месте' ? () async {


                                              ShPref.setHasTask(false);
                                              locations = _locationService!.getLocations();


                                              var data = {
                                                'ip': Host.ip,
                                                'id': brigadeTask.id,
                                                'cords' : jsonEncode(locations),
                                                'status': 'Завершено'
                                              };


                                              var socketData = {
                                                'id' : brigadeTask.id,
                                                'status' : 'Завершено',
                                              };

                                              Response response = await ServerSideApi.create(Host.ip, 1).updateStatus(data).whenComplete(() async {
                                                _webSocketChannel!.sink.add(json.encode(socketData));
                                              });


                                              if (response.body == 'status_updated') {
                                                Navigator.pop(context);
                                                _bottomNavBarItemIndex = 2;
                                                setState(() {});
                                              }
                                            } : null
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: 300,
                                        child: FloatingActionButton.extended(
                                            label: const Center(
                                              child: Text('Не завершено'),
                                            ),
                                            backgroundColor: Colors.red,
                                            onPressed: () async {

                                              ShPref.setHasTask(false);
                                              locations = _locationService!.getLocations();


                                              var data = {
                                                'ip': Host.ip,
                                                'id': brigadeTask.id,
                                                'cords' : jsonEncode(locations),
                                                'status': 'Не завершено'
                                              };

                                              var socketData = {
                                                'id' : brigadeTask.id,
                                                'status' : 'Не завершено',
                                              };

                                              Response response = await ServerSideApi.create(Host.ip, 1).updateStatus(data).whenComplete(() async {
                                                _webSocketChannel!.sink.add(json.encode(socketData));
                                              });

                                              await ServerSideApi.create(Host.ip, 1).updateStatus(data).whenComplete(() async {
                                                _webSocketChannel!.sink.add(json.encode(socketData));
                                              });


                                              if (response.body == 'status_updated') {
                                                Navigator.pop(context);
                                                _bottomNavBarItemIndex = 2;
                                                setState(() {});
                                              }
                                            }
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Divider(
                                        height: 10,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 5),
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
          },
        );
      }
    );
  }

  // Building tasks history for specific brigade
  Widget buildTasksHistory(List<TaskServerModel>? _tasksHistory){
    return ListView.builder(
      itemCount: _tasksHistory!.length,
      itemBuilder: (context, index){
        TaskServerModel _task = _tasksHistory[index];
        return InkWell(
          onTap: (){
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
                          contentPadding: const EdgeInsets.only(left: 5, right: 5, bottom: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                          backgroundColor: Colors.white,
                          children: [
                            const SizedBox(height: 5),
                            Center(
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      _task.task,
                                      style: TextStyle(color: Color(
                                          int.parse('0x' + _task.color))),
                                    ),
                                    leading: const Icon(Icons.task),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Время в пути', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(_task.onWayTime),
                                      ],
                                    ),
                                    leading: const Icon(
                                        Icons.timelapse),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Время работы', style: TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(_task.workTime),
                                      ],
                                    ),
                                    leading: const Icon(Icons.timelapse),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Общее время работы', style: TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 3),
                                          Text(_task.allTaskTime),
                                        ],
                                      ),
                                      leading: const Icon(
                                          Icons.timelapse)
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: 300,
                                    child: FloatingActionButton.extended(
                                      label: const Text('Закрыть'),
                                      backgroundColor: Colors.deepOrange,
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
          child: Card(
              elevation: 5,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_task.task, style: TextStyle(
                              color: Color(int.parse('0x' + _task.color)),
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(height: 10),
                              Text(_task.status, style: TextStyle(color: _task.status == 'Завершено' ? Colors.green : Colors.red, fontSize: 20)),
                              SizedBox(height: 10),
                              Text(_task.date + '    ' + _task.time, style: TextStyle(color: Colors.grey))
                            ],
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(_task.address!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 5),
                          _task.note1 != '' || _task.note2 != '' ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Примечание', style: TextStyle(fontSize: 20, color: Colors.grey[700])),
                            ],
                          ) : Container(),
                          _task.note1 != '' ? Text(_task.note1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Container(),
                          _task.note2 != '' ? Text(_task.note2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)) : Container(),
                          const SizedBox(height: 5)
                        ],
                      ),
                    )
                  ]
              )
          ),
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
      onPressed: () async {
        var data = {
        'brigade' : UserState.getBrigade(),
        'status' : 'Offline'
       };

        await ServerSideApi.create(Host.ip, 1).updateBrigadeStatus(data);

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

  // Listening socket
  void _listenSocket(TaskServerModel? brigadeTask){
    _socketBroadcastStream!.listen((event) {
      Map<String, dynamic> eventMap = json.decode(event);
      String? taskId = eventMap['id'];
      String? brigade = eventMap['brigade'];

      bool? newTask = eventMap['new_task'];
      bool? deleteTask = eventMap['delete_task'];

      if(deleteTask == true && brigade == UserState.getBrigade()){
        ShPref.setHasTask(false);
        setState((){});
      }

      if(newTask == true && brigade == UserState.getBrigade()){
        setState((){});
      }

      if(brigade == UserState.getBrigade() && brigadeTask!.id == taskId){
        eventMap.forEach((key, value) {
          switch (key) {
            case 'task':
              if (eventMap['task'] != null) {
                taskState!(() {
                  brigadeTask.task = eventMap['task'];
                });
              }
              break;
            case 'address':
              if (eventMap['address'] != null) {
                taskState!(() {
                  brigadeTask.address = eventMap['address'];
                });
              }
              break;
            case 'color':
              if (eventMap['color'] != null) {
                taskState!(() {
                  brigadeTask.color = eventMap['color'];
                });
              }
              break;
            case 'date':
              if (eventMap['date'] != null) {
                taskState!(() {
                  brigadeTask.date = eventMap['date'];
                });
              }
              break;
            case 'time':
              if (eventMap['time'] != null) {
                taskState!(() {
                  brigadeTask.time = eventMap['time'];
                });
              }
              break;
            case 'note1':
              if (eventMap['note1'] != null) {
                taskState!(() {
                  brigadeTask.note1 = eventMap['note1'];
                });
              }
              break;
            case 'note2':
              if (eventMap['note2'] != null) {
                taskState!(() {
                  brigadeTask.note2 = eventMap['note2'];
                });
              }
              break;
            case 'telephone':
              if(eventMap['telephone'] != null){
                brigadeTask.telephone = eventMap['telephone'];
              }
              break;
            case 'urgent':
              if(eventMap['urgent'] != null){
                brigadeTask.isUrgent = eventMap['urgent'].toString();
              }
          }
        });

        switch (eventMap['status']) {
          case 'Не выполнено':
            ShPref.setHasTask(false);
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
            ShPref.setHasTask(false);
            setState(() {
              _bottomNavBarItemIndex = 2;
            });
            break;
        }
      }
    });
  }
}