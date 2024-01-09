import 'dart:async';

class DelayedFunctionCaller {
  final void Function() function;
  final Duration duration;
  Timer? _timer;

  DelayedFunctionCaller(this.function, this.duration);

  get scheduled => _timer != null && _timer!.isActive;

  void call() {
    // If a timer is already active, return.
    if (_timer != null && _timer!.isActive) {
      return;
    }

    // Create a timer that calls the function after the specified duration.
    _timer = Timer(duration, function);
  }
}
