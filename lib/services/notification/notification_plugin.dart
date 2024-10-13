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
      payload: message['message'],
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


  Future<void> scheduleNotification() async {
    // var androidChannelSpecifics = const AndroidNotificationDetails(
    //   'CHANNEL_ID 1',
    //   'CHANNEL_NAME 1',
    //   icon: 'secondary_icon',
    //   sound: RawResourceAndroidNotificationSound('my_sound'),
    //   largeIcon: DrawableResourceAndroidBitmap('large_notf_icon'),
    //   enableLights: true,
    //   color: Color.fromARGB(255, 255, 0, 0),
    //   ledColor: Color.fromARGB(255, 255, 0, 0),
    //   ledOnMs: 1000,
    //   ledOffMs: 500,
    //   importance: Importance.max,
    //   priority: Priority.high,
    //   playSound: true,
    //   timeoutAfter: 5000,
    //   styleInformation: DefaultStyleInformation(true, true),
    // );



    // await flutterLocalNotificationsPlugin.schedule(
    //   0,
    //   'Test Title',
    //   'Test Body',
    //   scheduleNotificationDateTime,
    //   platformChannelSpecifics,
    //   payload: 'Test Payload',
    // );
  }


  // Future<void> showNotificationWithAttachment() async {
  //   // var attachmentPicturePath = await _downloadAndSaveFile(
  //   //     'https://via.placeholder.com/800x200', 'attachment_img.jpg');
  //   var bigPictureStyleInformation = BigPictureStyleInformation(
  //     FilePathAndroidBitmap(attachmentPicturePath),
  //     contentTitle: '<b>Attached Image</b>',
  //     htmlFormatContentTitle: true,
  //     summaryText: 'Test Image',
  //     htmlFormatSummaryText: true,
  //   );
  //   var androidChannelSpecifics = AndroidNotificationDetails(
  //     'CHANNEL ID 2',
  //     'CHANNEL NAME 2',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     styleInformation: bigPictureStyleInformation,
  //   );
  //   var notificationDetails =
  //   NotificationDetails(android: androidChannelSpecifics);
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     'Title with attachment',
  //     'Body with Attachment',
  //     notificationDetails,
  //   );
  // }


  Future<int> getPendingNotificationCount() async {
    List<PendingNotificationRequest> p =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return p.length;
  }


  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
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