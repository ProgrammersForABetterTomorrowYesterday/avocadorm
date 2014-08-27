library avocadorm_test;

import 'dart:async';
import 'dart:math';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';
import 'entities/entities.dart';

part 'mock_database_handler.dart';

void main() {

  group('Constructing the avocadorm', () {

    test('instance is created', () {

      expect(
          new Avocadorm(new MockDatabaseHandler()),
          isNotNull,
          reason: 'Avocadorm should return a valid instance.');

    });

  });

  group('Creating entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal creation with an entity', () {

      var newId = 12,
          newName = 'New Entity!',
          newEntity = new EntityA()
            ..entityAId = newId
            ..name = newName
            ..entityBId = null;

      avocadorm.create(newEntity).then(expectAsync((id) {

        expect(
            id,
            isNot(equals(newId)),
            reason: 'The create() method should ignore any specified entity id.');

        expect(
            id,
            equals(6),
            reason: 'The create() method should return the new entity\'s id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Created entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(newName),
              reason: 'Created entity should have the name that was given.');

        }));

      }));

    });

    test('Normal creation with an entity map', () {

      var newId = 12,
          newName = 'New Entity!',
          newEntityMap = { 'entityAId': newId, 'name': newName, 'entityBId': null };

      avocadorm.createFromMap(EntityA, newEntityMap).then(expectAsync((id) {

        expect(
            id,
            isNot(equals(newId)),
            reason: 'The create() method should ignore any specified entity id.');

        expect(
            id,
            equals(6),
            reason: 'createWithMap() should return the new entity\'s id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Created entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(newName),
              reason: 'Created entity should have the name that was given.');

        }));

      }));

    });

    test('Invalid usages when creating with an entity', () {

      expect(
          () => avocadorm.create(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.create('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when creating with an entity map', () {

      expect(
          () => avocadorm.createFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.createFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.createFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.createFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

  });

  group('Reading entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal read of a list of entities', () {

      avocadorm.readAll(EntityA).then(expectAsync((entities) {

        expect(
            entities.length,
            equals(5),
            reason: 'There should be 5 instances of type EntityA.');

        expect(
            entities.every((e) => e is EntityA),
            isTrue,
            reason: 'All retrieved entities should be of type EntityA. Found other types.');

      }));

      avocadorm.readAll(EntityB).then(expectAsync((entities) {

        expect(
            entities.length,
            equals(6),
            reason: 'There should be 6 instances of type EntityB.');

        expect(
            entities.every((e) => e is EntityB),
            isTrue,
            reason: 'All retrieved entities should be of type EntityB. Found other types.');

      }));

    });

    test('Normal read of an entity', () {

      avocadorm.readById(EntityA, 2).then(expectAsync((entity) {

        expect(
            entity,
            isNotNull,
            reason: 'The readById() method should return an instance of type EntityA.');

        expect(
            entity.entityAId,
            equals(2),
            reason: 'The EntityA that was read has the wrong id.');

        expect(
            entity.name,
            'Second EntityA',
            reason: 'The EntityA that was read has the wrong name.');

        expect(
            entity.entityBId,
            equals(2),
            reason: 'The EntityA that was read has the wrong entityB id.');

        expect(
            entity.entityB,
            isNull,
            reason: 'The EntityA that was read has the wrong foreign key value (shoud be null, since no foreignKey was asked for).');

      }));

      avocadorm.readById(EntityB, 3).then(expectAsync((entity) {

        expect(
            entity,
            isNotNull,
            reason: 'The readById() method should return an instance of type EntityB.');

        expect(
            entity.entityBId,
            equals(3),
            reason: 'The EntityB that was read has the wrong id.');

        expect(
            entity.name,
            'Third EntityB',
            reason: 'The EntityB that was read has the wrong name.');

        expect(
            entity.entityAs,
            isNull,
            reason: 'The EntityB that was read has the wrong foreign key value (shoud be null, since no foreignKey was asked for).');

      }));

    });

    test('Normal read of an entity (foreign keys)', () {

      avocadorm.readById(EntityA, 2, foreignKeys: ['entityB']).then(expectAsync((entity) {

        expect(
            entity,
            isNotNull,
            reason: 'The readById() method should return an instance of type EntityA.');

        expect(
            entity.entityBId,
            equals(2),
            reason: 'The EntityA that was read has the wrong entityB id.');

        expect(
            entity.entityB,
            isNotNull,
            reason: 'The EntityA that was read has the wrong foreign key value.');

        expect(
            entity.entityB.entityBId,
            equals(entity.entityBId),
            reason: 'The EntityA that was read has the wrong foreign key value');

      }));

      avocadorm.readById(EntityB, 3, foreignKeys: ['entityAs']).then(expectAsync((entity) {

        expect(
            entity,
            isNotNull,
            reason: 'The readById() method should return an instance of type EntityB.');

        expect(
            entity.entityAs,
            isNotNull,
            reason: 'The EntityB that was read has the wrong foreign key value.');

        expect(
            entity.entityAs is List,
            isTrue,
            reason: 'The EntityB that was read has the wrong foreign key value.');

        expect(
            entity.entityAs.length,
            equals(1),
            reason: 'The EntityB that was read has the wrong foreign key value.');

        expect(
            entity.entityAs.first.entityAId,
            equals(4),
            reason: 'The EntityB that was read has the wrong foreign key value.');

      }));

    });

    test('Invalid usages when reading a list of entities', () {

      expect(
          () => avocadorm.readAll(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.readAll('Invalid type'),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('Invalid usages when reading an entity', () {

      expect(
          () => avocadorm.readById(null, 0),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.readById('Invalid Type', 0),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.readById(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.readById(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value that is not of a value type should throw an exception.');

    });

  });

  group('Updating entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal update with an entity', () {

      var entityId = 12,
          entityName = 'Entity!',
          entity = new EntityA()
            ..entityAId = entityId
            ..name = entityName
            ..entityBId = null;

      avocadorm.update(entity).then(expectAsync((id) {

        expect(
            id,
            equals(entityId),
            reason: 'The update() method should not change the entity id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Updated entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(entityName),
              reason: 'Updated entity should have the name that was given.');

        }));

      }));

    });

    test('Normal update with an entity map', () {

      var entityId = 12,
          entityName = 'Entity!',
          entityMap = { 'entityAId': entityId, 'name': entityName, 'entityBId': null };

      avocadorm.updateFromMap(EntityA, entityMap).then(expectAsync((id) {

        expect(
            id,
            equals(entityId),
            reason: 'The update() method should not change the entity id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Updated entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(entityName),
              reason: 'Updated entity should have the name that was given.');

        }));

      }));

    });

    test('Invalid usages when updating with an entity', () {

      expect(
          () => avocadorm.update(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.update('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when updating with an entity map', () {

      expect(
          () => avocadorm.updateFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.updateFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.updateFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.updateFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

  });

  group('Saving entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal save with an entity', () {

      var entityId = 12,
          entityName = 'Entity!',
          entity = new EntityA()
            ..entityAId = entityId
            ..name = entityName
            ..entityBId = null;

      avocadorm.save(entity).then(expectAsync((id) {

        expect(
            id,
            equals(entityId),
            reason: 'The save() method should not change the entity id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Saved entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(entityName),
              reason: 'Saved entity should have the name that was given.');

        }));

      }));

    });

    test('Normal save with an entity map', () {

      var entityId = 12,
          entityName = 'Entity!',
          entityMap = { 'entityAId': entityId, 'name': entityName, 'entityBId': null };

      avocadorm.saveFromMap(EntityA, entityMap).then(expectAsync((id) {

        expect(
            id,
            equals(entityId),
            reason: 'The save() method should not change the entity id.');

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Saved entity should be retrievable, but was not found.');

          expect(
              entityA.name,
              equals(entityName),
              reason: 'Saved entity should have the name that was given.');

        }));

      }));

    });

    test('Invalid usages when saving with an entity', () {

      expect(
          () => avocadorm.save(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.save('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when saving with an entity map', () {

      expect(
          () => avocadorm.saveFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.saveFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.saveFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.saveFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

  });

  group('Deleting entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal creation with an entity', () {

      var entityId = 2,
          entity = new EntityA()
            ..entityAId = entityId
            ..name = 'New Entity!'
            ..entityBId = null;

      avocadorm.delete(entity).then(expectAsync((r) {

        avocadorm.readById(EntityA, entityId).then(expectAsync((entityA) {

          expect(
              entityA,
              isNull,
              reason: 'Deleted entity should not be readable.');

        }));

      }));

    });

    test('Normal creation with an id', () {

      var entityId = 2;

      avocadorm.deleteById(EntityA, entityId).then(expectAsync((r) {

        avocadorm.readById(EntityA, entityId).then(expectAsync((entityA) {

          expect(
              entityA,
              isNull,
              reason: 'Deleted entity should not be readable.');

        }));

      }));

    });

    test('Invalid usages when creating with an entity', () {

      expect(
          () => avocadorm.create(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.create('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when creating with an entity map', () {

      expect(
          () => avocadorm.readById(null, 0),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.readById('Invalid Type', 0),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.readById(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.readById(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value that is not of a value type should throw an exception.');

    });

  });

}
