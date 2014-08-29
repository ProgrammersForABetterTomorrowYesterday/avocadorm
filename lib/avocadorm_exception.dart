part of magnetfruit_avocadorm;

class AvocadormException implements Exception {
  String message;

  AvocadormException([this.message = '']);

  String toString() => "AvocadormException: $message";
}
