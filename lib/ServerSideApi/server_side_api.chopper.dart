// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_side_api.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$ServerSideApi extends ServerSideApi {
  _$ServerSideApi([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = ServerSideApi;

  @override
  Future<Response<Brigade>> loginBrigade(dynamic data) {
    final $url = '/login_brigade.php';
    final $body = data;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<Brigade, Brigade>($request);
  }

  @override
  Future<Response<dynamic>> updateStatus(dynamic data) {
    final $url = '/update_status.php';
    final $body = data;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateBrigadeStatus(dynamic data) {
    final $url = '/update_brigade_status.php';
    final $body = data;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<List<TaskServerModel>>> getBrigadeTask(dynamic data) {
    final $url = '/get_brigade_tasks.php';
    final $body = data;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<List<TaskServerModel>, TaskServerModel>($request);
  }

  @override
  Future<Response<List<TaskServerModel>>> getBrigadeTasksHistory(dynamic data) {
    final $url = '/get_brigade_tasks_history.php';
    final $body = data;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<List<TaskServerModel>, TaskServerModel>($request);
  }
}
