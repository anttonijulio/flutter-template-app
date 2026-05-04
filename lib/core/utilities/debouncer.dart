import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get isActiveStream => _controller.stream;
  bool get isActive => _timer?.isActive ?? false;

  Debouncer(this.delay);

  void call(void Function() action) {
    _timer?.cancel();
    _controller.add(true);
    _timer = Timer(delay, () {
      _controller.add(false);
      action();
    });
  }

  void dispose() {
    _timer?.cancel();
    _controller.add(false);
    _controller.close();
  }
}
