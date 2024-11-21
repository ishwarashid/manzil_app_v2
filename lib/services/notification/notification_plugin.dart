import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';

class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
  didReceivedLocalNotificationSubject =
  BehaviorSubject<ReceivedNotification>();
  var initializationSettings;

  var isForeground = true;


  NotificationPlugin._() {
    init();
  }


  init() async {
    initializePlatformSpecifics();
  }


  initializePlatformSpecifics() {
    var initializationSettingsAndroid =
    const AndroidInitializationSettings('ic_stat_m');

    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);
  }


  Future<void> requestPermissions() async {
    var notificationsEnabled = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!.areNotificationsEnabled();

    if(!notificationsEnabled!){
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()!.requestNotificationsPermission();
    }
  }


  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceivedLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }


  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) => onNotificationClick(payload));
  }

  Future<void> showNotification(message) async {
    var androidChannelSpecifics = const AndroidNotificationDetails(
      '1',
      'ChatChannel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: "ic_stat_m",
      styleInformation: DefaultStyleInformation(true, true),
      category: AndroidNotificationCategory.social
    );

    var platformChannelSpecifics =
    NotificationDetails(android: androidChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      message['_id'].hashCode,
      message['senderName'],
      message['message'],
      platformChannelSpecifics,
      payload: jsonEncode(message),
    );
  }

  Future<void> repeatNotification() async {
    var androidChannelSpecifics = const AndroidNotificationDetails(
      'CHANNEL_ID 3',
      'CHANNEL_NAME 3',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: DefaultStyleInformation(true, true),
    );

    var platformChannelSpecifics =
    NotificationDetails(android: androidChannelSpecifics);
    await flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      'Repeating Test Title',
      'Repeating Test Body',
      RepeatInterval.everyMinute,
      platformChannelSpecifics,
      payload: 'Test Payload',
    );
  }



  Future<int> getPendingNotificationCount() async {
    List<PendingNotificationRequest> p =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return p.length;
  }


  Future<void> cancelNotification(message) async {
    await flutterLocalNotificationsPlugin.cancel(message['_id'].hashCode);
  }


  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}


NotificationPlugin notificationPlugin = NotificationPlugin._();


class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
}