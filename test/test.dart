library avocadorm_test;

import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';
import 'dart:math';
import 'entities/entities.dart';

part 'mock_database_handler.dart';

void main() {

  setEntities();

  test('instance is created', () {

    expect(
      new Avocadorm(new MockDatabaseHandler()),
      isNotNull,
      reason: 'Avocadorm should return a valid instance.');

  });

  var avocadorm;

  setUp(() {
    avocadorm = new Avocadorm(new MockDatabaseHandler());
    avocadorm.addEntities([EntityA, EntityB, EntityC]);
  });

  test('Retrieving all entities', () {

    avocadorm.retrieveAll(EntityA).then(expectAsync((entities) {

      expect(
        entities.length,
        equals(5),
        reason: 'There should be 5 instances of type EntityA.');

    }));

  });

  test('Retrieving an entity by id', () {

    avocadorm.retrieveById(EntityA, 2).then(expectAsync((entity) {

      expect(
          entity,
          isNotNull,
          reason: 'retrieveById() should return an instance of type EntityA.');

    }));

  });

  test('Creating an entity (auto_increment id)', () {

    var newEntity = { 'name': 'New Entity!', 'entity_b_id': null };

    avocadorm.save(EntityA, newEntity).then(expectAsync((id) {

      expect(
          id,
          equals(6),
          reason: 'retrieveById() should return an instance of type EntityB.');

    }));

  });

  test('Creating an entity (specified id)', () {

    var newEntity = { 'entity_a_id': 12, 'name': 'New Entity!', 'entity_b_id': null };

    avocadorm.save(EntityA, newEntity).then(expectAsync((id) {

      expect(
          id,
          equals(12),
          reason: 'retrieveById() should return an instance of type EntityB.');

    }));

  });

  test('Updating an entity', () {

    var entity = { 'entity_a_id': 5, 'name': 'Fifth EntityA', 'entity_b_id': null };

    avocadorm.save(EntityA, entity).then(expectAsync((id) {

      expect(
          id,
          equals(5),
          reason: 'retrieveById() should return an instance of type EntityB.');

    }));

  });

  test('Deleting en entity', () {

    avocadorm.delete(EntityA, 2).then(expectAsync((r) {

      expect(
          r,
          isNull,
          reason: 'retrieveById() should return an instance of type EntityB.');

    }));

  });

}