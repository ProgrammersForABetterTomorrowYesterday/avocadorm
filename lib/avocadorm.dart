library magnetfruit_avocadorm;

import 'dart:async';
import 'dart:mirrors';
import 'package:magnetfruit_entity/entity.dart';

part 'database_handler/database_handler.dart';
part 'property/foreign_key_property.dart';
part 'property/primary_key_property.dart';
part 'property/property.dart';
part 'property/property_filter.dart';
part 'resource_handler/resource.dart';
part 'resource_handler/resource_exception.dart';

class Avocadorm {

  DatabaseHandler _databaseHandler;
  List<Resource> _resources;

  Avocadorm(DatabaseHandler databaseHandler) {
    if (databaseHandler == null) {
      throw new ArgumentError('Argument \'databaseHandler\' must not be null.');
    }

    if (databaseHandler is! DatabaseHandler) {
      throw new ArgumentError('Argument \'databaseHandler\' should be a DatabaseHandler.');
    }

    this._databaseHandler = databaseHandler;
    this._resources = [];
  }

  void addEntitiesInLibrary(String libraryName) {
    LibraryMirror lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));

    lib.declarations.values
      .where((dm) => dm is ClassMirror)
      .map((dm) => dm as ClassMirror)
      .where((cm) => cm.isSubtypeOf(reflectType(Entity)))
      .map((cm) => cm.reflectedType)
      .forEach(addEntity);
  }

  void addEntities(List<Type> entityTypes) {
    if (entityTypes == null) {
      throw new ArgumentError('Argument \'entityTypes\' must not be null.');
    }

    if (entityTypes is! Iterable) {
      throw new ArgumentError('Argument \'entityTypes\' should be a list of Entity classes.');
    }

    entityTypes.forEach(addEntity);
  }

  void addEntity(Type entityType) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity class.');
    }

    this._resources.add(new Resource(entityType));
  }


  Future<List<Entity>> retrieveAll(Type entityType, {List<PropertyFilter> filters, List<String> loadForeignKeys}) {
    var resource = this._getResource(entityType);

    if (resource == null) {
      throw new ResourceException('Resource not found for entity ${entityType}.');
    }

    var columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName);

    return this._databaseHandler.retrieveAll(resource.tableName, columns, filters)
      .then((entities) => entities.map((e) => convertToEntity(e, resource)))
      .then((entities) => Future.wait(entities.map((e) => _retrieveForeignKeys(e, loadForeignKeys))));
  }

  Future<Entity> retrieveById(Type entityType, Object primaryKeyValue, {List<String> loadForeignKeys}) {
    if (primaryKeyValue == null) {
      return new Future.value(null);
    }

    var resource = this._getResource(entityType),
        columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName),
        pkColumn = resource.primaryKeyProperty.columnName;

    return this._databaseHandler.retrieveById(resource.tableName, columns, pkColumn, primaryKeyValue)
      .then((entity) => convertToEntity(entity, resource))
      .then((entity) => _retrieveForeignKeys(entity, loadForeignKeys));
  }

  Future<Object> save(Type entityType, Map data) {
    var resource = this._getResource(entityType),
        columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName),
        pkColumn = resource.primaryKeyProperty.columnName;

    return this._databaseHandler.save(resource.tableName, columns, pkColumn, data)
      .then((pkValue) {
        this._saveForeignKeys(entityType, data);
        return pkValue;
      });
  }

  Future delete(Type entityType, Object primaryKeyValue) {
    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName;

    return this._databaseHandler.delete(resource.tableName, pkColumn, primaryKeyValue);
  }


  Resource _getResource(Type entityType) {
    return this._resources.firstWhere((r) => r.type == entityType, orElse: null);
  }

  Future<Entity> _retrieveForeignKeys(Entity entity, List<String> loadForeignKeys) {
    if (entity == null) {
      return new Future.value(null);
    }

    if (loadForeignKeys == null) {
      loadForeignKeys = [];
    }

    Resource resource = this._getResource(entity.runtimeType);
    var futures = [];

    InstanceMirror entityMirror = reflect(entity);

    resource.foreignKeyProperties
      .where((p) => loadForeignKeys.any((fk) => fk == p.name || fk.startsWith('${p.name}.')))
      .forEach((p) {
        var future = null;

        if (p.isManyToOne) {
          var id = entityMirror.getField(new Symbol(p.targetName)).reflectee;

          future = this.retrieveById(
              p.type,
              id,
              loadForeignKeys: traverseLoadForeignKeyList(loadForeignKeys, p.name));
        }
        else if (p.isOneToMany) {
          var targetResource = this._resources[p.type];
          var targetProperty = targetResource.simpleProperties.firstWhere((tp) => tp.name == p.targetName);
          var targetValue = entityMirror.getField(new Symbol(resource.primaryKeyProperty.name)).reflectee;

          future = this.retrieveAll(
              p.type,
              filters: [new PropertyFilter(targetProperty, targetValue)],
              loadForeignKeys: traverseLoadForeignKeyList(loadForeignKeys, p.name));
        }

        if (future != null) {
          futures.add(future.then((e) => entityMirror.setField(new Symbol(p.name), e)));
        }
      });

    return Future.wait(futures).then((r) => entity);
  }

  Future _saveForeignKeys(Type entityType, Map data) {
    var futures = [],
        resource = this._getResource(entityType);

    resource.foreignKeyProperties
      .where((fk) => fk.onUpdateOperation == ReferentialAction.CASCADE)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) => futures.add(this.save(fk.type, data[fk.name])));

    return Future.wait(futures);
  }


  static Entity convertToEntity(Map data, Resource resource) {
    if (data == null) {
      return null;
    }

    InstanceMirror entityMirror = reflectClass(resource.type).newInstance(new Symbol(''), []);

    resource.simpleAndPrimaryKeyProperties.forEach((p) {
      entityMirror.setField(new Symbol(p.name), data[p.columnName]);
    });

    return entityMirror.reflectee;
  }

  static List<String> traverseLoadForeignKeyList(List<String> loadForeignKeys, String propertyName) {
    var traversedLoadForeignKeys = loadForeignKeys
      .where((fk) => fk == propertyName || fk.startsWith('${propertyName}.'))
      .map((fk) => fk.substring(propertyName.length))
      .where((fk) => fk.isNotEmpty)
      .map((fk) => trimLeft(fk, '.'));

    return distinct(traversedLoadForeignKeys);
  }

  static String trimLeft(String input, String trimChar) {
    int pos = 0;

    while (pos < input.length && input[pos] == trimChar) {
      pos++;
    }

    return input.substring(pos);
  }

  static List distinct(List input) {
    var output = [];

    input.forEach((i) {
      if (!output.contains(i)) {
        output.add(i);
      }
    });

    return output;
  }
}
