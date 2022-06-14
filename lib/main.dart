import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chopper/chopper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intermax_task_manager/Brigades%20Settings/brigade_details.dart';
import 'package:intermax_task_manager/Flutter%20Toast/flutter_toast.dart';
import 'package:intermax_task_manager/ServerSideApi/server_side_api.dart';
import 'package:intermax_task_manager/Shared%20Preferences/sh_pref.dart';
import 'package:intermax_task_manager/User%20Details/user_details.dart';
import 'package:intermax_task_manager/User%20State/user_state.dart';
import 'package:intermax_task_manager/host.dart';
import 'package:intermax_task_manager/tasks_page.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:universal_platform/universal_platform.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserState.init();
  await Firebase.initializeApp();
  await ShPref.init();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
          channelKey: 'high_importance_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Intermax Task Manager',
          defaultRingtoneType: DefaultRingtoneType.Notification,
          importance: NotificationImportance.High,
          enableVibration: true,
      )
    ],
  );
  runApp(const MaterialApp(
    home: TaskManagerMainPage(),
  )
  );
}

class TaskManagerMainPage extends StatefulWidget {
  const TaskManagerMainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<TaskManagerMainPage> {

  var _ipAddressFieldFocusNode;
  var _nameFieldFocus;
  var _passwordFieldFocus;

  ShowMessage? _showMessage;


  @override
  void initState() {
    super.initState();

    _showMessage = ShowMessage.init();
    _ipAddressFieldFocusNode = FocusNode();
    _nameFieldFocus = FocusNode();
    _passwordFieldFocus = FocusNode();

    UserState.getSignInStatus()!.then((status) {
      if(status == true){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskPage()));
      }
    });
  }


  @override
  void dispose() {
    super.dispose();

    _ipAddressFieldFocusNode.dispose();
    _nameFieldFocus.dispose();
    _passwordFieldFocus.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper.builder(
      Scaffold(
          appBar: AppBar(
          title:  const Text('Планировщик задач Intermax', style: TextStyle(fontSize: 25)),
          centerTitle: false,
          backgroundColor: Colors.deepOrangeAccent,
          automaticallyImplyLeading: false,
        ),
        body: loginInterface()
      ),
      breakpoints: const [
        ResponsiveBreakpoint.resize(500, name: MOBILE),
        ResponsiveBreakpoint.resize(800, name: TABLET),
        ResponsiveBreakpoint.resize(1000, name: DESKTOP),
      ],
      defaultScale: true,
    );
  }

  // Login interface
  StatefulBuilder loginInterface(){
    TextEditingController ipController = TextEditingController();
    TextEditingController nameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    if (UserState.getIP() != null && UserState.getUserName() != null && UserState.getPassword() != null) {
      ipController.value = ipController.value.copyWith(text: UserState.getIP());
      nameController.value = nameController.value.copyWith(text: UserState.getUserName());
      passwordController.value = passwordController.value.copyWith(text: UserState.getPassword());
    }

    List<TextEditingController> controllers = [
      ipController,
      nameController,
      passwordController
    ];

    var _isHidden = true;
    var _isChecked = false;

    double? height = MediaQuery.of(context).size.height;
    double? width = MediaQuery.of(context).size.width;

    return StatefulBuilder(
      builder: (context, setState){
        return Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: SizedBox(
              width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      cursorColor: Colors.deepOrangeAccent,
                      focusNode: _nameFieldFocus,
                      keyboardType: TextInputType.text,
                      controller: nameController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0)),
                        label: const Text('Имя пользователя'),
                        labelStyle: TextStyle(color: _nameFieldFocus.hasFocus ? Colors.deepOrangeAccent : Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: const BorderSide(
                            color: Colors.deepOrangeAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onTap: () {
                        FocusScope.of(context).requestFocus(_nameFieldFocus);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      cursorColor: Colors.deepOrangeAccent,
                      focusNode: _passwordFieldFocus,
                      keyboardType: TextInputType.text,
                      obscureText: _isHidden,
                      controller: passwordController,
                      decoration: InputDecoration(
                          contentPadding:const EdgeInsets.symmetric(vertical: 25.0, horizontal: 25.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          label: const Text('Пароль'),
                          labelStyle: TextStyle(color: _passwordFieldFocus.hasFocus ? Colors.deepOrangeAccent : Colors.grey),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(
                              color: Colors.deepOrangeAccent,
                              width: 2.0,
                            ),
                          ),
                          suffixIcon: IconButton(
                            color: _passwordFieldFocus.hasFocus ? Colors.deepOrangeAccent : Colors.black,
                            icon: Icon(!_isHidden
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isHidden = !_isHidden;
                              });
                            },
                          )),
                      onTap: (){
                        FocusScope.of(context).requestFocus(_passwordFieldFocus);
                      },
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isChecked,
                            checkColor: Colors.white,
                            activeColor: Colors.deepOrangeAccent,
                            onChanged: (value){
                              setState(() {
                                _isChecked = value!;
                              });
                            },
                          ),
                          const SizedBox(width: 2),
                          const Text(
                              'Запомнить меня',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 70,
                      width: 300,
                      child: FloatingActionButton.extended(
                          backgroundColor: Colors.deepOrangeAccent,
                          label: const Text(
                            'Войти',
                          style: TextStyle(fontSize: 17)),
                          onPressed: () => _loginBrigade(controllers, _isChecked)
                      ),
                    )
                  ],
                )
            ),
          ),
        );
      },
    );
  }

  // Brigade login
  Future _loginBrigade(List<TextEditingController> controllersList, bool isChecked) async {
    var name = controllersList[1].text;
    var password = controllersList[2].text;

    Brigade? brigadeData;
    var data = {'ip': Host.ip, 'name': name, 'password': password};

    return Future.wait([
      ServerSideApi.create(Host.ip, 4).loginBrigade(data).then((value) => brigadeData = value.body),
    ]).whenComplete(() async {
      if(name == '' || password == '') {
        _showMessage!.show(context, 3);
      } else {
        if(brigadeData!.status == 'account_exists'){
          _showMessage!.show(context, 4);
          UserState.rememberBrigade(brigadeData!.brigade);
          if(isChecked == true){
            setState(() {
              UserState.userName = brigadeData!.username;
              UserState.rememberUser(Host.ip, brigadeData!.username, password);
            });
          }else{
            setState(() {
              UserState.userName = brigadeData!.username;
            });
          }


          var data = {
            'brigade' : brigadeData!.brigade,
            'status' : 'Online'
          };

         await ServerSideApi.create(Host.ip, 1).updateBrigadeStatus(data);


          UserState.rememberUserState(true);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskPage()));
        }else if (brigadeData!.status == 'account_not_exists'){
          _showMessage!.show(context, 5);
        }
      }
    });
  }
}
