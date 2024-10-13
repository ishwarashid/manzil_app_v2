import 'package:flutter/material.dart';
import 'package:manzil_app_v2/services/notification/notification_plugin.dart';

class BackgroundDetector extends StatefulWidget {
  const BackgroundDetector({
    required this.child,
    super.key
  });

  final Widget child;

  @override
  State<BackgroundDetector> createState() => _BackgroundDetectorState();
}

class _BackgroundDetectorState extends State<BackgroundDetector>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notificationPlugin.isForeground = true;

    }

    if (state == AppLifecycleState.paused) {
      notificationPlugin.isForeground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}