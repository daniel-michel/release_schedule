import 'dart:async';

import 'package:http/http.dart' as http;

class RateLimitStatus {
  int consecutiveCount = 0;
  Duration timeout = const Duration(seconds: 1);
}

class ApiManager {
  String baseUrl;
  Future<void> ongoingRequest = Future.value();
  int consecutiveRateLimitExceeded = 0;
  Duration rateLimitTimeout = Duration.zero;
  DateTime? lastRequest;

  ApiManager(this.baseUrl);

  Future<http.Response> get(String path) async {
    Future<void> waitingForRequest = ongoingRequest;
    Completer completer = Completer();
    try {
      ongoingRequest = completer.future;
      await waitingForRequest;

      DateTime? lastRequestLocal = lastRequest;
      if (consecutiveRateLimitExceeded > 0 &&
          lastRequestLocal != null &&
          DateTime.now().isBefore(lastRequestLocal.add(rateLimitTimeout))) {
        throw Exception("Too many requests");
      }

      http.Response response = await http.get(Uri.parse(baseUrl + path));
      lastRequest = DateTime.now();
      if (response.statusCode == 429) {
        consecutiveRateLimitExceeded++;
        if (consecutiveRateLimitExceeded == 1) {
          rateLimitTimeout = const Duration(seconds: 1);
        } else {
          rateLimitTimeout *= 2;
        }
        String? retryAfter = response.headers["Retry-After"];
        if (retryAfter != null) {
          int? retryAfterSeconds = int.tryParse(retryAfter);
          if (retryAfterSeconds != null) {
            Duration retryAfterDuration = Duration(seconds: retryAfterSeconds);
            if (retryAfterDuration > rateLimitTimeout) {
              rateLimitTimeout = retryAfterDuration;
            }
          }
        }
        throw Exception("Too many requests");
      } else {
        consecutiveRateLimitExceeded = 0;
      }
      return response;
    } finally {
      completer.complete();
    }
  }
}
