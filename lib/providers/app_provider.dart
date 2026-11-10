import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool busy = false;
  String? busyMessage;

  void showBusy([String? msg]) {
    busy = true;
    busyMessage = msg;
    notifyListeners();
  }

  void hideBusy() {
    busy = false;
    busyMessage = null;
    notifyListeners();
  }
}
