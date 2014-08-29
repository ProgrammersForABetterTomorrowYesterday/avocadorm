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

  group('Specifying the entities', () {
    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());
    });

    test('Specifying a library of entity', () {

      expect(
          () => avocadorm.addEntitiesInLibrary(null),
          throwsArgumentError,
          reason: 'A null library name should throw an exception.');

      expect(
          () => avocadorm.addEntitiesInLibrary({'type': 'Invalid type'}),
          throwsArgumentError,
          reason: 'A library name of an invalid type should throw an exception.');

      expect(
          () => avocadorm.addEntitiesInLibrary('Invalid library name'),
          throwsArgumentError,
          reason: 'An invalid library name should throw an exception.');

      expect(
          avocadorm.addEntitiesInLibrary('entities'),
          equals(2),
          reason: 'A valid library name should not throw an exception.');

    });

    test('Specifying a list of entity', () {

      expect(
          () => avocadorm.addEntities(null),
          throwsArgumentError,
          reason: 'A null list of entity type should throw an exception.');

      expect(
          () => avocadorm.addEntities('Invalid type'),
          throwsArgumentError,
          reason: 'A list of entity type that is not a list should throw an exception.');

      expect(
          () => avocadorm.addEntities(['Invalid type']),
          throwsArgumentError,
          reason: 'An list of entity type in which an entity type is of an invalid type should throw an exception.');

      expect(
          avocadorm.addEntities([EntityA, EntityB]),
          equals(2),
          reason: 'A valid library name should not throw an exception.');

    });

    test('Specifying an entity', () {

      expect(
          () => avocadorm.addEntity(null),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.addEntity('Invalid type'),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          avocadorm.addEntity(EntityA),
          equals(1),
          reason: 'A valid library name should not throw an exception.');

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

    test('Invalid creation when id already in database', () {
      var entity = new EntityA()
            ..entityAId = 2
            ..name = 'Conflict!'
            ..entityBId = null;

      expect(
        avocadorm.create(entity),
        throwsA(new isInstanceOf<AvocadormException>()),
        reason: 'Creating an entity already in the database should throw an exception.');

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

  group('Counting entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm(new MockDatabaseHandler());

      avocadorm.addEntities([EntityA, EntityB]);
    });

    test('Normal count of entities', () {

      avocadorm.count(EntityA).then(expectAsync((count) {

        expect(
            count,
            equals(5),
            reason: 'The count() method should have found 5 EntityA entities.');

      }));

      avocadorm.count(EntityB).then(expectAsync((count) {

        expect(
            count,
            equals(6),
            reason: 'The count() method should have found 6 EntityB entities.');

      }));

    });

    test('Normal count of entities by primary key value', () {

      avocadorm.hasId(EntityA, 2).then(expectAsync((isFound) {

        expect(
            isFound,
            isTrue,
            reason: 'The hasId() method should have found 1 EntityA entity for the primary key value 2.');

      }));

      avocadorm.hasId(EntityB, 20).then(expectAsync((isFound) {

        expect(
            isFound,
            isFalse,
            reason: 'The hasId() method should not have found any EntityB entity for the primary key value 20.');

      }));

    });

    test('Normal count of entities by filter', () {

      avocadorm.count(EntityA, [new Filter('entity_b_id', 2)]).then(expectAsync((count) {

        expect(
            count,
            equals(2),
            reason: 'The count() method should have found 2 EntityA entities with the property \'entity_b_id\' equal to 2.');

      }));

      avocadorm.count(EntityB, [new Filter('name', 'Fourth EntityB')]).then(expectAsync((count) {

        expect(
            count,
            equals(1),
            reason: 'The count() method should have found 1 EntityB entity with the property \'name\' equal to \'Fourth EntityB\'.');

      }));

      avocadorm.count(EntityA, [new Filter('name', 'Not Found')]).then(expectAsync((count) {

        expect(
            count,
            equals(0),
            reason: 'The count() method should not have found any EntityA entity with the property \'name\' equal to \'Not Found\'.');

      }));

    });

    test('Invalid usages when counting entities', () {

      expect(
          () => avocadorm.count(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.count('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when counting entities by primary key value', () {

      expect(
          () => avocadorm.hasId(null, 0),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.hasId('Invalid Type', 0),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.hasId(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.hasId(EntityA, {}),
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

      avocadorm.readById(EntityB, 20).then(expectAsync((entity) {

        expect(
            entity,
            isNull,
            reason: 'The readById() method should return null if the entity does not exist in the database.');

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

      var entityId = 3,
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

      var entityId = 3,
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

    test('Invalid update when id not in database', () {
      var entity = new EntityA()
          ..entityAId = 20
          ..name = 'Not found!'
          ..entityBId = null;

      expect(
          avocadorm.update(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Updating an entity not in the database should throw an exception.');

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

    test('Valid save when id not in database', () {
      var entityId = 20,
          entity = new EntityA()
          ..entityAId = entityId
          ..name = 'Not found!'
          ..entityBId = null;

      avocadorm.save(entity).then(expectAsync((id) {

        expect(
            id,
            equals(entityId),
            reason: 'The save() method should not change the entity id.');

      }));

    });

    skip_test('Normal save with new m2o foreign key', () {

      var entityAId = 3,
          entityBId = 10,
          entityBName = 'New EntityB',
          entityB = new EntityB()
            ..entityBId = entityBId
            ..name = entityBName,
          entity = new EntityA()
            ..entityAId = entityAId
            ..name = 'EntityA'
            ..entityBId = entityBId
            ..entityB = entityB;

      avocadorm.save(entity).then(expectAsync((id) {

        avocadorm.readById(EntityB, entityBId).then(expectAsync((entityB) {

          expect(
              entityB,
              isNotNull,
              reason: 'Created foreign key entity should be retrievable, but was not found.');

          expect(
              entityB.name,
              equals(entityBName),
              reason: 'Created foreign key entity should have the name that was given.');

        }));

      }));

    });

    test('Normal save with new o2m foreign keys', () { });

    test('Normal save with existing m2o foreign key', () { });

    test('Normal save with existing o2m foreign keys', () { });

    // Id of foreign key is set on original entity.
    test('Normal save with conflicting foreign key id', () { });

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

    test('Normal deletion with an entity', () {

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

    test('Normal deletion with an id', () {

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

    test('Invalid deletion when id not in database', () {
      var entity = new EntityA()
          ..entityAId = 20
          ..name = 'Not found!'
          ..entityBId = null;

      expect(
          avocadorm.delete(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Deleting an entity not in the database should throw an exception.');

    });

    test('Invalid usages when deleting with an entity', () {

      expect(
          () => avocadorm.delete(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.delete('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('Invalid usages when deleting with an entity map', () {

      expect(
          () => avocadorm.deleteById(null, 0),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.deleteById('Invalid Type', 0),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.deleteById(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.deleteById(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value that is not of a value type should throw an exception.');

    });

  });

}
