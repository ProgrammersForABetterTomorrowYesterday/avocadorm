library avocadorm_test;

import 'dart:async';
import 'dart:math';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:magnetfruit_database_handler/database_handler.dart';
import 'package:mock/mock.dart';
import 'package:unittest/unittest.dart';
import 'entities/entities.dart';
import 'entities/invalid_entities.dart';

part 'mock_database_handler.dart';

void main() {

  tearDown(()  {
    // Clears the singleton's database handler and entities.
    new Avocadorm().clear();
  });

  group('Constructing the avocadorm', () {

    test('returns the instance', () {

      expect(
          new Avocadorm(),
          isNotNull,
          reason: 'Avocadorm should return a valid instance.');

    });

  });

  group('Specifying the database handler', () {

    var avocadorm;

    setUp(() {
      avocadorm = new Avocadorm();
    });

    test('accepts a valid database handler', () {

      expect(
          () => avocadorm.setDatabaseHandler(new MockDatabaseHandler()),
          returnsNormally,
          reason: 'Avocadorm should return a valid instance.');

    });

    test('throws if the database handler is null', () {

      expect(
          () => avocadorm.setDatabaseHandler(null),
          throwsArgumentError,
          reason: 'A null database handler should throw an exception.');

    });

    test('throws if the database handler is invalid', () {

      expect(
          () => avocadorm.setDatabaseHandler('Invalid Type'),
          throwsArgumentError,
          reason: 'A database handler of an invalid type should throw an exception.');

    });

  });

  group('Specifying the entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler());
    });

    test('adds the entities in the specified library and returns the count', () {

      expect(
          avocadorm.addEntitiesInLibrary('entities'),
          equals(3),
          reason: 'A valid library name should return the number of entities added.');

    });

    test('adds the entities in the specified list of entity type and returns the count', () {

      expect(
          avocadorm.addEntities([EntityA, EntityB]),
          equals(2),
          reason: 'A valid list of entity type should return the number of entities added.');

    });

    test('add the specified entity and returns 1', () {

      expect(
          avocadorm.addEntity(EntityA),
          equals(1),
          reason: 'A valid entity type should return the value 1.');

    });

    test('throws if the library is null', () {

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

    });

    test('throws if the list of entity type is invalid', () {

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
          reason: 'An list of entity type in which an item is of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.addEntity(null),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.addEntity('Invalid type'),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

  });

  group('Validating the avocadorm', () {

    var avocadorm;

    setUp(() {
      avocadorm = new Avocadorm();
    });

    tearDown(()  {
      // Clears the singleton's database handler and entities.
      avocadorm.clear();
    });

    test('is unactive if it is missing a database handler and entities', () {

      expect(
          avocadorm.isActive,
          isFalse,
          reason: 'The Avocadorm should not be active if the database handler and entities are missing.');

    });

    test('is unactive if it is missing entities', () {

      avocadorm.setDatabaseHandler(new MockDatabaseHandler());

      expect(
          avocadorm.isActive,
          isFalse,
          reason: 'The Avocadorm should not be active if the database handler is missing.');

    });

    test('is unactive if it is missing a database handler', () {

      avocadorm.addEntity(EntityA);

      expect(
          avocadorm.isActive,
          isFalse,
          reason: 'The Avocadorm should not be active if the database handler is missing.');

    });

    test('is active if the database handler and entities are specified', () {

      avocadorm.setDatabaseHandler(new MockDatabaseHandler());
      avocadorm.addEntity(EntityA);

      expect(
          avocadorm.isActive,
          isTrue,
          reason: 'The Avocadorm should be active if the database handler is specified.');

    });

    test('denies the operations if unactive', () {

      avocadorm.addEntity(EntityA);

      expect(
          () => avocadorm.create(new EntityA()),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Creating an entity should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.createFromMap(EntityA, {}),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Creating an entity from a map should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.count(EntityA),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Counting entities should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.hasId(EntityA, 1),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Counting an entity by id should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.read(EntityA),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Reading entities should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.readById(EntityA, 1),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Reading an entity by id should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.update(new EntityA()),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Updating an entity should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.updateFromMap(EntityA, {}),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Updating an entity from a map should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.save(new EntityA()),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Saving an entity should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.saveFromMap(EntityA, {}),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Saving an entity from a map should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.delete(new EntityA()),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Deleting an entity should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.deleteById(EntityA, 1),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Deleting an entity should not be possible if the avocadorm is unactive.');

      expect(
          () => avocadorm.deleteFromMap(EntityA, {}),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Deleting an entity from a map should not be possible if the avocadorm is unactive.');


    });

  });

  group('Constructing a resource from an entity type', () {

    var avocadorm;

    setUp(() {
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler());
    });

    test('throws if the entity type does not have a Table metadata', () {

      expect(
          () => avocadorm.addEntity(EntityNoTable),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'An entity should have a Table metadata.');

    });

    test('throws if a primary key is of an invalid type', () {

      expect(
          () => avocadorm.addEntity(PkInvalidEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A primary key should be a number or a string.');

    });

    test('throws if a m2o foreign key is not of an entity type', () {

      expect(
          () => avocadorm.addEntity(FkInvalidM2OTypeEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A m2o foreign key should be of an entity type.');

    });

    test('throws if a m2o foreign key doesn\'t point to a property in the class', () {

      expect(
          () => avocadorm.addEntity(FkInvalidM2OIdEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A m2o foreign key should point to a property in the same class.');

    });

    test('throws if a o2m foreign key is not a list', () {

      expect(
          () => avocadorm.addEntity(FkInvalidO2MListEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A o2m foreign key should be a list.');

    });

    test('throws if a o2m foreign key is not a list of an entity type', () {

      expect(
          () => avocadorm.addEntity(FkInvalidO2MTypeEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A o2m foreign key should be a list of entity type.');

    });

    test('throws if a o2m foreign key does not point to a property in the target entity', () {

      expect(
          () => avocadorm.addEntity(FkInvalidO2MTargetEntity),
          throwsA(new isInstanceOf<ResourceException>()),
          reason: 'A o2m foreign key should point to a property in the target entity.');

    });

  });

  group('Creating an entity', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('ignores the specified primary key value', () {

      var entity = new EntityA()
            ..entityAId = 10
            ..name = 'New entity';

      avocadorm.create(entity).then(expectAsync((id) {

        expect(
            id,
            isNot(equals(entity.entityAId)),
            reason: 'The create() method should ignore any specified entity id.');

      }));

    });

    test('gives it the next available primary key value', () {

      var entity = new EntityA()
            ..name = 'New entity';

      avocadorm.create(entity).then(expectAsync((id) {

        expect(
            id,
            equals(6),
            reason: 'The create() method should return the new entity\'s id.');

      }));

    });

    test('saves it to the database', () {

      var entity = new EntityA()
            ..name = 'New entity';

      avocadorm.create(entity).then(expectAsync((id) {

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA,
              isNotNull,
              reason: 'Created entity should be retrievable, but was not found.');

        }));

      }));

    });

    test('saves the correct values', () {

      var entity = new EntityA()
            ..name = 'New entity'
            ..entityBId = 2;

      avocadorm.create(entity).then(expectAsync((id) {

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA.name,
              equals(entity.name),
              reason: 'Created entity should correctly save a string property.');

          expect(
              entityA.entityBId,
              equals(entity.entityBId),
              reason: 'Created entity should correctly save an int property.');

        }));

      }));

    });

    test('throws if the primary key value already exists', () {

      var entity = new EntityA()
            ..entityAId = 2
            ..name = 'New entity';

      expect(
          avocadorm.create(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Creating an entity already in the database should throw an exception.');

    });

    test('throws if the entity is invalid', () {

      expect(
          () => avocadorm.create(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.create('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.createFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.createFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity map is invalid', () {

      expect(
          () => avocadorm.createFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.createFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      var entity = new EntityC()
            ..name = 'Entity C';

      expect(
          () => avocadorm.create(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Counting entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('returns whether a specific entity exists', () {

      avocadorm.hasId(EntityA, 2).then(expectAsync((isFound) {

        expect(
            isFound,
            isTrue,
            reason: 'The hasId() method should have found an EntityA entity for the primary key value 2.');

      }));

      avocadorm.hasId(EntityB, 20).then(expectAsync((isFound) {

        expect(
            isFound,
            isFalse,
            reason: 'The hasId() method should not have found any EntityB entity for the primary key value 20.');

      }));

    });

    test('returns the count of a given entity', () {

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

    test('returns the count of a given entity, filtered by the specified filter', () {

      avocadorm.count(EntityA, filters: [new Filter('entityBId', 2)]).then(expectAsync((count) {

        expect(
            count,
            equals(2),
            reason: 'The count() method should have found 2 EntityA entities with the property \'entityBId\' equal to 2.');

      }));

      avocadorm.count(EntityB, filters: [new Filter('name', 'Fourth EntityB')]).then(expectAsync((count) {

        expect(
            count,
            equals(1),
            reason: 'The count() method should have found 1 EntityB entity with the property \'name\' equal to \'Fourth EntityB\'.');

      }));

      avocadorm.count(EntityA, filters: [new Filter('name', 'Not Found')]).then(expectAsync((count) {

        expect(
            count,
            equals(0),
            reason: 'The count() method should not have found any EntityA entity with the property \'name\' equal to \'Not Found\'.');

      }));

    });

    test('throws if the entity is invalid', () {

      expect(
          () => avocadorm.count(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.count('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.hasId(null, 0),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.hasId('Invalid Type', 0),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity primary key value is invalid', () {

      expect(
          () => avocadorm.hasId(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.hasId(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      expect(
          () => avocadorm.count(EntityC),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Reading entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('returns all entities of the specified type', () {

      avocadorm.read(EntityA).then(expectAsync((entityAs) {

        expect(
            entityAs,
            isNotNull,
            reason: 'Reading all entities should return a list all instances of the specified entity.');

        expect(
            entityAs.length,
            equals(5),
            reason: 'The number of entityA instances should be 6.');

      }));

    });

    test('returns the entity matching the specified primary key value', () {

        avocadorm.readById(EntityA, 2).then(expectAsync((entityA) {

        expect(
            entityA,
            isNotNull,
            reason: 'Reading an entity by its id should return the instance of that entity.');

        expect(
            entityA.name,
            equals('Second EntityA'),
            reason: 'The name of the EntityA matching primary key value 2 should be \'Second EntityA\'.');

      }));

    });

    test('returns null if the specified primary key value doesn\'t match any entity', () {

      avocadorm.readById(EntityA, 10).then(expectAsync((entityA) {

        expect(
            entityA,
            isNull,
            reason: 'Reading an entity by its id should return null if not matched.');

      }));

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.read(null),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.read('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.readById(null, 1),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.readById('Invalid Type', 1),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity primary key value is invalid', () {

      expect(
          () => avocadorm.readById(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.readById(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      expect(
          () => avocadorm.read(EntityC),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Reading entities with filters', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('returns all entities matching the filter', () {

      avocadorm.read(EntityA, filters: [new Filter('entityBId', 2)]).then(expectAsync((entityAs) {

        expect(
            entityAs.length,
            equals(2),
            reason: 'The number of entityA instances with entityBId equal to 2 should be 6.');

      }));

    });

  });

  group('Reading entities with foreign keys', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('returns an entity with the specified foreign key', () {

      avocadorm.readById(EntityA, 4, foreignKeys: ['entityB']).then(expectAsync((entityA) {

        expect(
            entityA.entityB,
            isNotNull,
            reason: 'The entityA property \'entityB\' should have been retrieved.');

        expect(
            entityA.entityB.name,
            equals('Third EntityB'),
            reason: 'The entityA property \'entityB\' should have the correct name \'Third EntityB\'.');

      }));

    });

    test('returns an entity with the specified chained foreign key', () {

      avocadorm.readById(EntityA, 4, foreignKeys: ['entityB.entityAs']).then(expectAsync((entityA) {

        expect(
            entityA.entityB.entityAs,
            isNotNull,
            reason: 'The foreign key \'entityB.entityAs\' should have been retrieved.');

        expect(
            entityA.entityB.entityAs.length,
            equals(1),
            reason: 'The foreign key \'entityB.entityAs\' should have one instance of EntityA.');

      }));

    });

  });

  group('Updating entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('updates the matching entity in the database', () {

      var entity = new EntityA()
            ..entityAId = 3
            ..name = 'Entity A'
            ..entityBId = null;

      avocadorm.update(entity).then(expectAsync((id) {

        expect(
            id,
            equals(entity.entityAId),
            reason: 'The update() method should not change the entity id.');

        avocadorm.hasId(EntityA, id).then(expectAsync((isFound) {

          expect(
              isFound,
              isTrue,
              reason: 'Updated entity should be retrievable, but was not found.');

        }));

      }));

    });

    test('updates the correct values', () {

      var entity = new EntityA()
            ..entityAId = 3
            ..name = 'Entity A'
            ..entityBId = null;

      avocadorm.update(entity).then(expectAsync((id) {

        avocadorm.readById(EntityA, id).then(expectAsync((entityA) {

          expect(
              entityA.name,
              equals(entity.name),
              reason: 'Updated entity should have the name that was given.');

        }));

      }));

    });

    test('throws if the primary key value does not exist', () {

      var entity = new EntityA()
            ..entityAId = 20
            ..name = 'New entity';

      expect(
          avocadorm.update(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Updating an entity not in the database should throw an exception.');

    });

    test('throws if the entity is invalid', () {

      expect(
          () => avocadorm.update(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.update('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.updateFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.updateFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity map is invalid', () {

      expect(
          () => avocadorm.updateFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.updateFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      var entity = new EntityC()
            ..entityCId = '2'
            ..name = 'Entity C';

      expect(
          () => avocadorm.update(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Saving entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('creates the entity when the primary key value is non-existant', () {

      var entity = new EntityA()
        ..entityAId = 10
        ..name = 'Entity A'
        ..entityBId = null;

      avocadorm.hasId(EntityA, entity.entityAId).then(expectAsync((isFound) {

        expect(isFound, isFalse, reason: 'EntityA with primary key value 10 should not exist.');

        avocadorm.save(entity).then(expectAsync((id) {

          avocadorm.hasId(EntityA, id).then(expectAsync((isFound) {

            expect(isFound, isTrue, reason: 'Updated entity should be retrievable, but was not found.');

          }));

        }));

      }));

    });

    test('respects the specified primary key value when creating the entity', () {

      var entity = new EntityA()
        ..entityAId = 10
        ..name = 'Entity A'
        ..entityBId = null;

      avocadorm.save(entity).then(expectAsync((id) {

        expect(id, equals(entity.entityAId), reason: 'The update() method should not change the entity id.');

      }));

    });

    test('updates the entity when the primary key value is existant', () {

      var entity = new EntityA()
        ..entityAId = 3
        ..name = 'Entity A'
        ..entityBId = null;

      avocadorm.hasId(EntityA, entity.entityAId).then(expectAsync((isFound) {

        expect(isFound, isTrue, reason: 'EntityA with primary key value 3 should exist');

        avocadorm.save(entity).then(expectAsync((id) {

          expect(id, equals(entity.entityAId), reason: 'Updated entity should have the same primary key value.');

          avocadorm.hasId(EntityA, id).then(expectAsync((isFound) {

            expect(isFound, isTrue, reason: 'Updated entity should be retrievable, but was not found.');

          }));

        }));

      }));

    });

    test('throws if the entity is invalid', () {

      expect(() => avocadorm.save(null), throwsArgumentError, reason: 'A null entity should throw an exception.');

      expect(() => avocadorm.save('Invalid Type'), throwsArgumentError, reason: 'An entity of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(() => avocadorm.saveFromMap(null, {
      }), throwsArgumentError, reason: 'A null entity type should throw an exception.');

      expect(() => avocadorm.saveFromMap('Invalid Type', {
      }), throwsArgumentError, reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity map is invalid', () {

      expect(() => avocadorm.saveFromMap(EntityA, null), throwsArgumentError, reason: 'A null entity map should throw an exception.');

      expect(() => avocadorm.saveFromMap(EntityA, 'Invalid Type'), throwsArgumentError, reason: 'An entity map of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      var entity = new EntityC()
            ..entityCId = '2'
            ..name = 'Entity C';

      expect(
          () => avocadorm.save(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Saving entities with many-to-one foreign keys', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('will create the new foreign key', () {

      var entityFk = new EntityB()
            ..entityBId = 10
            ..name = 'New EntityB',
          entity = new EntityA()
            ..entityAId = 3
            ..name = 'EntityA'
            ..entityBId = entityFk.entityBId
            ..entityB = entityFk;

      avocadorm.hasId(EntityB, entityFk.entityBId).then(expectAsync((isFound) {

        expect(isFound, isFalse, reason: 'EntityB with primary key value 10 should not exist.');

        avocadorm.save(entity).then(expectAsync((id) {

          avocadorm.hasId(EntityB, entityFk.entityBId).then(expectAsync((isFound) {

            expect(isFound, isTrue, reason: 'EntityB with primary key value 10 should have been created.');

          }));

        }));

      }));

    });

    test('will update the existing foreign key', () {

      var entityFk = new EntityB()
            ..entityBId = 2
            ..name = 'EntityB',
          entity = new EntityA()
            ..entityAId = 3
            ..name = 'EntityA'
            ..entityBId = entityFk.entityBId
            ..entityB = entityFk;

      avocadorm.hasId(EntityB, entityFk.entityBId).then(expectAsync((isFound) {

        expect(isFound, isTrue, reason: 'EntityB with primary key value 2 should exist.');

        avocadorm.save(entity).then(expectAsync((id) {

          avocadorm.readById(EntityB, entityFk.entityBId).then(expectAsync((entityB) {

            expect(entityB, isNotNull, reason: 'EntityB should not have disappeared after the save.');

            expect(entityB.name, equals(entityFk.name), reason: 'EntityB should have been updated with the specified name.');

          }));

        }));

      }));

    });

    test('will set the parent entity\'s foreign key target id', () {

      var entityFk = new EntityB()
            ..entityBId = 15
            ..name = 'New EntityB',
          entity = new EntityA()
            ..entityAId = 3
            ..name = 'EntityA'
            ..entityBId = 14
            ..entityB = entityFk;

      avocadorm.save(entity).then(expectAsync((id) {

        avocadorm.hasId(EntityB, entity.entityBId).then(expectAsync((isFound) {

          expect(
              isFound,
              isFalse,
              reason: 'Foreign key should have been created under its own id, not its parent\'s.');

        }));

        avocadorm.hasId(EntityB, entityFk.entityBId).then(expectAsync((isFound) {

          expect(
              isFound,
              isTrue,
              reason: 'Foreign key should have been created under its own id.');

        }));

        avocadorm.readById(EntityA, entity.entityAId).then(expectAsync((entityA) {

          expect(
              entityA.entityBId,
              equals(entityFk.entityBId),
              reason: 'Entity still retains control of its foreign key.');

        }));

      }));

    });

  });

  group('Saving entities with one-to-many foreign keys', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('will create the new foreign keys', () {

      var entityFk1 = new EntityA()
            ..entityAId = 10
            ..name = 'New EntityA1',
          entityFk2 = new EntityA()
            ..entityAId = 11
            ..name = 'New EntityA2',
          entity = new EntityB()
            ..entityBId = 3
            ..name = 'EntityB'
            ..entityAs = [entityFk1, entityFk2];

      avocadorm.hasId(EntityA, entityFk1.entityAId).then(expectAsync((isFound) {

        expect(isFound, isFalse, reason: 'EntityA with primary key value 10 should not exist.');

        avocadorm.save(entity).then(expectAsync((id) {

          avocadorm.hasId(EntityA, entityFk1.entityAId).then(expectAsync((isFound) {

            expect(isFound, isTrue, reason: 'EntityA with primary key value 10 should have been created.');

          }));

          avocadorm.hasId(EntityA, entityFk2.entityAId).then(expectAsync((isFound) {

            expect(isFound, isTrue, reason: 'EntityA with primary key value 11 should have been created.');

          }));

        }));

      }));

    });

    test('will update the existing foreign keys', () {

      var entityFk1 = new EntityA()
            ..entityAId = 2
            ..name = 'EntityA1',
          entityFk2 = new EntityA()
            ..entityAId = 3
            ..name = 'EntityA2',
          entity = new EntityB()
            ..entityBId = 3
            ..name = 'EntityB'
            ..entityAs = [entityFk1, entityFk2];

      avocadorm.hasId(EntityA, entityFk1.entityAId).then(expectAsync((isFound) {

        expect(isFound, isTrue, reason: 'EntityA with primary key value 2 should exist.');

        avocadorm.save(entity).then(expectAsync((id) {

          avocadorm.readById(EntityA, entityFk1.entityAId).then(expectAsync((entityA) {

            expect(entityA, isNotNull, reason: 'First EntityA should not have disappeared after the save.');

            expect(entityA.name, equals(entityFk1.name), reason: 'First EntityA should have been updated with the specified name.');

          }));

          avocadorm.readById(EntityA, entityFk2.entityAId).then(expectAsync((entityA) {

            expect(entityA, isNotNull, reason: 'Second EntityA should not have disappeared after the save.');

            expect(entityA.name, equals(entityFk2.name), reason: 'Second EntityA should have been updated with the specified name.');

          }));

        }));

      }));

    });

    test('will set the entities\' foreign key target id', () {

      var entityFk1 = new EntityA()
            ..entityAId = 14
            ..entityBId = 15
            ..name = 'EntityA 1',
          entityFk2 = new EntityA()
            ..entityAId = 16
            ..entityBId = 17
            ..name = 'EntityA 2',
          entity = new EntityB()
            ..entityBId = 10
            ..name = 'EntityB'
            ..entityAs = [entityFk1, entityFk2];

      avocadorm.save(entity).then(expectAsync((id) {

        avocadorm.readById(EntityA, entityFk1.entityAId).then(expectAsync((entityA) {

          expect(
              entityA.entityBId,
              equals(entity.entityBId),
              reason: 'Foreign key should have its target id set to the parent entity\'s id.');

        }));

        avocadorm.readById(EntityB, entity.entityBId, foreignKeys: ['entityAs']).then(expectAsync((entityB) {

          expect(
              entityB.entityAs.length,
              equals(2),
              reason: 'Entity still retains control of its foreign key.');

        }));

      }));

    });

  });

  group('Deleting entities', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('removes the entity from the database', () {

      var entity = new EntityB()
            ..entityBId = 2
            ..name = 'Entity';

      avocadorm.delete(entity).then(expectAsync((r) {

        avocadorm.hasId(EntityB, entity.entityBId).then(expectAsync((isFound) {

          expect(
              isFound,
              isFalse,
              reason: 'Deleted entity should be removed.');

        }));

      }));

    });

    test('throws if the primary key value does not exist', () {

      var entity = new EntityA()
            ..entityAId = 20
            ..name = 'New entity';

      expect(
          avocadorm.delete(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Deleting an entity not in the database should throw an exception.');

    });

    test('throws if the entity is invalid', () {

      expect(
          () => avocadorm.delete(null),
          throwsArgumentError,
          reason: 'A null entity should throw an exception.');

      expect(
          () => avocadorm.delete('Invalid Type'),
          throwsArgumentError,
          reason: 'An entity of an invalid type should throw an exception.');

    });

    test('throws if the entity type is invalid', () {

      expect(
          () => avocadorm.deleteFromMap(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.deleteFromMap('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

      expect(
          () => avocadorm.deleteById(null, {}),
          throwsArgumentError,
          reason: 'A null entity type should throw an exception.');

      expect(
          () => avocadorm.deleteById('Invalid Type', {}),
          throwsArgumentError,
          reason: 'An entity type of an invalid type should throw an exception.');

    });

    test('throws if the entity map is invalid', () {

      expect(
          () => avocadorm.deleteFromMap(EntityA, null),
          throwsArgumentError,
          reason: 'A null entity map should throw an exception.');

      expect(
          () => avocadorm.deleteFromMap(EntityA, 'Invalid Type'),
          throwsArgumentError,
          reason: 'An entity map of an invalid type should throw an exception.');

    });

    test('throws if the entity primary key value is invalid', () {

      expect(
          () => avocadorm.deleteById(EntityA, null),
          throwsArgumentError,
          reason: 'A null primary key value should throw an exception.');

      expect(
          () => avocadorm.deleteById(EntityA, {}),
          throwsArgumentError,
          reason: 'A primary key value of an invalid type should throw an exception.');

    });

    test('throws if the entity was not added', () {

      var entity = new EntityC()
            ..entityCId = '2'
            ..name = 'Entity C';

      expect(
          () => avocadorm.delete(entity),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'A non-existant entity should throw an exception.');

    });

  });

  group('Deleting entities with many-to-one foreign keys', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB, EntityC]);
    });

    test('Normal deletion with a m2o foreign key', () {

      // onDelete Cascade is set on EntityA's entityB foreign key,
      //  so the entityB with id 3 should be deleted also.

      avocadorm.deleteById(EntityA, 4).then(expectAsync((r) {

        avocadorm.hasId(EntityB, 3).then(expectAsync((isFound) {

          expect(
              isFound,
              isFalse,
              reason: 'Many-to-one foreign key should have been deleted.');

        }));

      }));

    });

  });

  group('Deleting entities with one-to-many foreign keys', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB, EntityC]);
    });

    test('Normal deletion with a o2m foreign key', () {

      // onDelete Cascade is set on EntityA's entityCs foreign key,
      //   so all the entityC with entityAId 4 should be deleted also.

      avocadorm.deleteById(EntityA, 4).then(expectAsync((r) {

        avocadorm.read(EntityC, filters: [new Filter('entityAId', 4)]).then(expectAsync((entityCs) {

          expect(
              entityCs.length,
              equals(0),
              reason: 'One-to-many foreign keys should have been deleted.');

        }));

      }));

    });

  });

  group('Filters', () {

    var avocadorm;

    setUp(() {
      setEntities();
      avocadorm = new Avocadorm()
        ..setDatabaseHandler(new MockDatabaseHandler())
        ..addEntities([EntityA, EntityB]);
    });

    test('throws if the filter list is invalid', () {

      expect(
          () => avocadorm.count(EntityA, filters: 'Invalid type'),
          throwsArgumentError,
          reason: 'A filter list of an invalid type should throw an exception.'
      );

      expect(
          () => avocadorm.count(EntityA, filters: [null]),
          throwsArgumentError,
          reason: 'A null filter should throw an exception.'
      );

      expect(
          () => avocadorm.count(EntityA, filters: ['Invalid type']),
          throwsArgumentError,
          reason: 'A filter of an invalid type should throw an exception.'
      );

    });

    test('throws if the specified property can\'t be found', () {

      expect(
          () => avocadorm.count(EntityA, filters: [new Filter('notFound', 1)]),
          throwsA(new isInstanceOf<AvocadormException>()),
          reason: 'Non-existing property in filter should throw an exception.'
      );

    });

  });

}
