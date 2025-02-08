import 'package:flutter/foundation.dart';

class ShareProvider extends ChangeNotifier {
  void shareCurrentChat() {
    notifyListeners();
  }
}
