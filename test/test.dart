library avocadorm_test;

import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';

part 'mock_database_handler.dart';

void main() {

  test('instance is created', () {

    expect(
      new Avocadorm(new MockDatabaseHandler()),
      isNotNull,
      reason: 'Avocadorm should return a valid instance.');

  });

}