import 'dart:async';

import 'package:event_bus/event_bus.dart';

class CodePreviewEvent {
  final String textContent;
  final Map<String, String> attributes;

  const CodePreviewEvent(this.textContent, this.attributes);
}

class ToggleCodePreviewEvent {
  final bool showCodePreview;

  const ToggleCodePreviewEvent(this.showCodePreview);
}

class ShareEvent {
  final bool share;

  const ShareEvent(this.share);
}

/// The global [EventBus] object.
EventBus eventBus = EventBus();

Future<void> emit<T>(T data) async {
  eventBus.fire(data);
}

StreamSubscription<T> on<T>(Function(T) callback) {
  StreamSubscription<T> loginSubscription = eventBus.on<T>().listen((data) {
    callback(data);
  });

  return loginSubscription;
}
