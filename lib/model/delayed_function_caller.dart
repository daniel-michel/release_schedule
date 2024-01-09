import 'dart:async';

class DelayedFunctionCaller {
  final void Function() function;
  final Duration duration;
  final bool resetTimerOnCall;
  Timer? _timer;

  DelayedFunctionCaller(this.function, this.duration,
      {this.resetTimerOnCall = false});

  get scheduled => _timer != null && _timer!.isActive;

  void call() {
    if (_timer != null && _timer!.isActive) {
      // If a timer is already active and we don't want to reset it, return.
      if (!resetTimerOnCall) {
        return;
      }
      _timer!.cancel();
    }

    // Create a timer that calls the function after the specified duration.
    _timer = Timer(duration, function);
  }
}
