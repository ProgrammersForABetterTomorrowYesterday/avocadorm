library magnetfruit_avocadorm;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';
import 'package:magnetfruit_entity/entity.dart';

part 'avocadorm_exception.dart';
part 'database_handler/database_handler.dart';
part 'database_handler/filter.dart';
part 'property/foreign_key_property.dart';
part 'property/primary_key_property.dart';
part 'property/property.dart';
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


  Future<Object> create(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        data = this._convertFromEntity(entity);

    return this._create(entityType, data);
  }

  Future<Object> createFromMap(Type entityType, Map entityMap) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (entityMap == null) {
      throw new ArgumentError('Argument \'entityMap\' must not be null.');
    }

    if (entityMap is! Map) {
      throw new ArgumentError('Argument \'entityMap\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        data = this._convertFromEntityMap(entityMap, resource);

    return this._create(entityType, data);
  }

  Future<bool> hasId(Type entityType, Object primaryKeyValue) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (primaryKeyValue == null) {
      throw new ArgumentError('Argument \'primaryKeyValue\' must not be null.');
    }

    if (primaryKeyValue != null && primaryKeyValue is! num && primaryKeyValue is! String) {
      throw new ArgumentError('Argument \'primaryKeyValue\' should be a value type.');
    }

    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        filters = [new Filter(pkColumn, primaryKeyValue)];

    return this._count(entityType, filters: filters)
      .then((count) => count > 0);
  }

  Future<int> count(Type entityType, [List<Filter> filters]) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    return this._count(entityType, filters: filters);
  }

  Future<List<Entity>> readAll(Type entityType, {List<Filter> filters, List<String> foreignKeys}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    return this._read(entityType, filters: filters, foreignKeys: foreignKeys);
  }

  Future<Entity> readById(Type entityType, Object primaryKeyValue, {List<String> foreignKeys}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (primaryKeyValue == null) {
      throw new ArgumentError('Argument \'primaryKeyValue\' must not be null.');
    }

    if (primaryKeyValue is! num && primaryKeyValue is! String) {
      throw new ArgumentError('Argument \'primaryKeyValue\' should be a value type.');
    }

    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        filters = [new Filter(pkColumn, primaryKeyValue)];

    return this._read(entityType, filters: filters, foreignKeys: foreignKeys, limit: 1)
      .then((entities) => entities.length > 0 ? entities.first : null);
  }

  Future<Object> update(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        dbMap = this._convertFromEntity(entity);

    return this._update(entityType, dbMap);
  }

  Future<Object> updateFromMap(Type entityType, Map entityMap) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (entityMap == null) {
      throw new ArgumentError('Argument \'entityMap\' must not be null.');
    }

    if (entityMap is! Map) {
      throw new ArgumentError('Argument \'entityMap\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        data = this._convertFromEntityMap(entityMap, resource);

    return this._update(entityType, data);
  }

  Future<Object> save(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        dbMap = this._convertFromEntity(entity);

    return this._update(entityType, dbMap);
  }

  Future<Object> saveFromMap(Type entityType, Map entityMap) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (entityMap == null) {
      throw new ArgumentError('Argument \'entityMap\' must not be null.');
    }

    if (entityMap is! Map) {
      throw new ArgumentError('Argument \'entityMap\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        data = this._convertFromEntityMap(entityMap, resource);

    return this._update(entityType, data);
  }

  Future delete(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.name,
        pkValue = reflect(entity).getField(new Symbol(pkColumn)).reflectee;

    return this._delete(entityType, pkValue);
  }

  Future deleteById(Type entityType, Object primaryKeyValue) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (primaryKeyValue == null) {
      throw new ArgumentError('Argument \'primaryKeyValue\' must not be null.');
    }

    if (primaryKeyValue is! num && primaryKeyValue is! String) {
      throw new ArgumentError('Argument \'primaryKeyValue\' should be a value type.');
    }

    return this._delete(entityType, primaryKeyValue);
  }


  Future<Object> _create(Type entityType, Map data) {
    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList();

    return this._count(entityType, filters: [new Filter(pkColumn, data[pkColumn])])
      .then((count) {
        if (count > 0) {
          throw new AvocadormException('Can not create entity - primary key value is already in the database.');
        }

        return this._databaseHandler.create(resource.tableName, pkColumn, columns, data)
          .then((pkValue) {
            this._saveForeignKeys(entityType, data);
            return pkValue;
          });
      });
}

  Future<int> _count(Type entityType, {List<Filter> filters}) {
    var resource = this._getResource(entityType);

    return this._databaseHandler.count(resource.tableName, filters);
  }

  Future<List<Entity>> _read(Type entityType, {List<Filter> filters, List<String> foreignKeys, int limit}) {
    var resource = this._getResource(entityType),
        columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName).toList();

    return this._databaseHandler.read(resource.tableName, columns, filters, limit)
      .then((entities) => entities.map((e) => this._convertToEntity(e, resource)))
      .then((entities) => Future.wait(entities.map((e) => _retrieveForeignKeys(e, foreignKeys))));
  }

  Future<Object> _update(Type entityType, Map data) {
    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList();

    return this._databaseHandler.update(resource.tableName, pkColumn, columns, data)
      .then((pkValue) {
        this._saveForeignKeys(entityType, data);
        return pkValue;
      });
  }

  Future _delete(Type entityType, Object pkValue) {
    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        filters = [new Filter(pkColumn, pkValue)];

    return this._databaseHandler.delete(resource.tableName, filters);
  }


  Resource _getResource(Type entityType) {
    var resource = this._resources.firstWhere((r) => r.type == entityType, orElse: null);

    if (resource == null) {
      throw new ResourceException('Resource not found for entity ${entityType}.');
    }

    return resource;
  }

  Future<Entity> _retrieveForeignKeys(Entity entity, List<String> foreignKeys) {
    if (entity == null) {
      return new Future.value(null);
    }

    if (foreignKeys == null) {
      foreignKeys = [];
    }

    Resource resource = this._getResource(entity.runtimeType);
    var futures = [];

    InstanceMirror entityMirror = reflect(entity);

    resource.foreignKeyProperties
      .where((p) => foreignKeys.any((fk) => fk == p.name || fk.startsWith('${p.name}.')))
      .forEach((p) {
        var future = null;

        if (p.isManyToOne) {
          var targetResource = this._getResource(p.type),
              targetPkColumn = targetResource.primaryKeyProperty.columnName,
              targetPkValue = entityMirror.getField(new Symbol(p.targetName)).reflectee,
              filters = [new Filter(targetPkColumn, targetPkValue)];

          future = this._read(
              p.type,
              filters: filters,
              foreignKeys: traverseForeignKeyList(foreignKeys, p.name),
              limit: 1)
            .then((entity) => entity.length > 0 ? entity.first : null);
        }
        else if (p.isOneToMany) {
          var targetResource = this._getResource(p.type);
          var targetColumn = targetResource.simpleProperties.firstWhere((tp) => tp.name == p.targetName).columnName;
          var targetValue = entityMirror.getField(new Symbol(resource.primaryKeyProperty.name)).reflectee;

          future = this._read(
              p.type,
              filters: [new Filter(targetColumn, targetValue)],
              foreignKeys: traverseForeignKeyList(foreignKeys, p.name));
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


  Entity _convertToEntity(Map data, Resource resource) {
    if (data == null) {
      return null;
    }

    var entityMirror = reflectClass(resource.type).newInstance(new Symbol(''), []);

    resource.simpleAndPrimaryKeyProperties.forEach((p) {
      entityMirror.setField(new Symbol(p.name), data[p.columnName]);
    });

    return entityMirror.reflectee;
  }

  Map _convertFromEntity(Entity entity) {
    if (entity == null) {
      return null;
    }

    var resource = _getResource(entity.runtimeType),
        map = new Map(),
        entityMirror = reflect(entity);

    resource.simpleAndPrimaryKeyProperties.forEach((p) {
      map[p.columnName] = entityMirror.getField(new Symbol(p.name)).reflectee;
    });

    return map;
  }

  Map _convertFromEntityMap(Map data, Resource resource) {
    if (data == null) {
      return null;
    }

    var map = new Map();

    resource.simpleAndPrimaryKeyProperties.forEach((p) {
      map[p.columnName] = data[p.name];
    });

    return map;
  }

  static List<String> traverseForeignKeyList(List<String> foreignKeys, String propertyName) {
    var traversedForeignKeys = foreignKeys
      .where((fk) => fk == propertyName || fk.startsWith('${propertyName}.'))
      .map((fk) => fk.substring(propertyName.length))
      .where((fk) => fk.isNotEmpty)
      .map((fk) => trimLeft(fk, '.'));

    return distinct(traversedForeignKeys);
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
