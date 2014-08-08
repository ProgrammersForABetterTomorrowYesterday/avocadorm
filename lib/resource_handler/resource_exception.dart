part of magnetfruit_avocadorm;

class ResourceException implements Exception {
  String message;

  ResourceException([this.message = '']);

  String toString() => "ResourceException: $message";
}
