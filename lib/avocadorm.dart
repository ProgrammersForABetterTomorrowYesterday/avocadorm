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

  int addEntitiesInLibrary(String libraryName) {
    if (libraryName == null) {
      throw new ArgumentError('Argument \'libraryName\' must not be null.');
    }

    if (libraryName is! String) {
      throw new ArgumentError('Argument \'libraryName\' must be a String.');
    }

    LibraryMirror lib;

    try {
      lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));
    } catch(e) {
      throw new ArgumentError('Argument \'libraryName\' must designate a valid library name.');
    }

    var count = 0;

    lib.declarations.values
      .where((dm) => dm is ClassMirror)
      .map((dm) => dm as ClassMirror)
      .where((cm) => cm.isSubtypeOf(reflectType(Entity)))
      .map((cm) => cm.reflectedType)
      .forEach((et) {
        if (this._addEntityResource(et)) {
          count++;
        }
      });

    return count;
  }

  int addEntities(List<Type> entityTypes) {
    if (entityTypes == null) {
      throw new ArgumentError('Argument \'entityTypes\' must not be null.');
    }

    if (entityTypes is! Iterable) {
      throw new ArgumentError('Argument \'entityTypes\' should be a list of Entity type.');
    }

    if (entityTypes.any((et) => et is! Type || !reflectType(et).isSubtypeOf(reflectType(Entity)))) {
      throw new ArgumentError('Argument \'entityTypes\' should be a list of Entity type.');
    }

    var count = 0;

    entityTypes.forEach((et) {
        if (this._addEntityResource(et)) {
          count++;
        }
      });

    return count;
  }

  int addEntity(Type entityType) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity class.');
    }

    return this._addEntityResource(entityType) ? 1 : 0;
  }

  bool _addEntityResource(Type entityType) {
    this._resources.add(new Resource(entityType));

    return true;
  }


  Future<Object> create(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        data = this._convertFromEntity(entity),
        filters = [new Filter(pk.columnName, data[pk.name])];

    data[pk.name] = null;

    return this._count(resource, filters: filters).then((count) {
      if (count > 0) {
        throw new AvocadormException('Can not create entity - primary key value is already in the database.');
      }

      return this._create(resource, data);
    });
  }

  Future<Object> createFromMap(Type entityType, Map data) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (data == null) {
      throw new ArgumentError('Argument \'data\' must not be null.');
    }

    if (data is! Map) {
      throw new ArgumentError('Argument \'data\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        filters = [new Filter(pk.columnName, data[pk.name])];

    data[pk.name] = null;

    return this._count(resource, filters: filters).then((count) {
      if (count > 0) {
        throw new AvocadormException('Can not create entity - primary key value is already in the database.');
      }

      return this._create(resource, data);
    });
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

    return this._count(resource, filters: filters)
      .then((count) => count > 0);
  }

  Future<int> count(Type entityType, {List<Filter> filters}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    var resource = this._getResource(entityType);

    return this._count(resource, filters: filters);
  }

  Future<List<Entity>> readAll(Type entityType, {List<Filter> filters, List<String> foreignKeys}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    var resource = this._getResource(entityType);

    return this._read(resource, filters: filters, foreignKeys: foreignKeys);
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

    return this._read(resource, filters: filters, foreignKeys: foreignKeys, limit: 1)
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
        resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        data = this._convertFromEntity(entity),
        filters = [new Filter(pk.columnName, data[pk.name])];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        throw new AvocadormException('Can not update entity - primary key value is not in the database.');
      }

      return this._update(resource, data);
    });
  }

  Future<Object> updateFromMap(Type entityType, Map data) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (data == null) {
      throw new ArgumentError('Argument \'data\' must not be null.');
    }

    if (data is! Map) {
      throw new ArgumentError('Argument \'data\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        filters = [new Filter(pk.columnName, data[pk.name])];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        throw new AvocadormException('Can not update entity - primary key value is not in the database.');
      }

      return this._update(resource, data);
    });
  }

  Future<Object> save(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Argument \'entity\' must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Argument \'entity\' should be an Entity.');
    }

    var entityType = entity.runtimeType,
        resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        data = this._convertFromEntity(entity),
        filters = [new Filter(pk.columnName, data[pk.name])];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        return this._create(resource, data);
      }
      else {
        return this._update(resource, data);
      }
    });
  }

  Future<Object> saveFromMap(Type entityType, Map data) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    if (data == null) {
      throw new ArgumentError('Argument \'data\' must not be null.');
    }

    if (data is! Map) {
      throw new ArgumentError('Argument \'data\' should be a Map.');
    }

    var resource = this._getResource(entityType),
        pk = resource.primaryKeyProperty,
        filters = [new Filter(pk.columnName, data[pk.name])];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        return this._create(resource, data);
      }
      else {
        return this._update(resource, data);
      }
    });
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
        pk = resource.primaryKeyProperty,
        pkValue = reflect(entity).getField(new Symbol(pk.name)).reflectee,
        filters = [new Filter(pk.columnName, pkValue)];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        throw new AvocadormException('Can not delete entity - primary key value is not in the database.');
      }

      return this._delete(resource, pkValue);
    });

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

    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        filters = [new Filter(pkColumn, primaryKeyValue)];

    return this._count(resource, filters: filters).then((count) {
      if (count == 0) {
        throw new AvocadormException('Can not delete entity - primary key value is not in the database.');
      }

      return this._delete(resource, primaryKeyValue);
    });

  }


  Future<Object> _create(Resource resource, Map data) {
    var pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList(),
        dbData = this._convertDataToDatabaseData(data, resource);

    return this._databaseHandler.create(resource.tableName, pkColumn, columns, dbData)
      .then((pkValue) {
        this._saveForeignKeys(resource, data);
        return pkValue;
      })
    .then((pkValue) {
      dbData = this._convertDataToDatabaseData(data, resource);
      dbData[pkColumn] = pkValue;
      return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData);
    });
}

  Future<int> _count(Resource resource, {List<Filter> filters}) {
    return this._databaseHandler.count(resource.tableName, filters);
  }

  Future<List<Entity>> _read(Resource resource, {List<Filter> filters, List<String> foreignKeys, int limit}) {
    var columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName).toList();

    return this._databaseHandler.read(resource.tableName, columns, filters, limit)
      .then((entities) => entities.map((e) => this._convertToEntity(e, resource)))
      .then((entities) => Future.wait(entities.map((e) => _retrieveForeignKeys(e, foreignKeys))));
  }

  Future<Object> _update(Resource resource, Map data) {
    var pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList(),
        dbData = this._convertDataToDatabaseData(data, resource);

    return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData)
      .then((pkValue) {
        this._saveForeignKeys(resource, data);
        return pkValue;
      })
      .then((pkValue) {
        dbData =  this._convertDataToDatabaseData(data, resource);
        return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData);
      });
  }

  Future _delete(Resource resource, Object pkValue) {
    var pkColumn = resource.primaryKeyProperty.columnName,
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
              this._getResource(p.type),
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
              this._getResource(p.type),
              filters: [new Filter(targetColumn, targetValue)],
              foreignKeys: traverseForeignKeyList(foreignKeys, p.name));
        }

        if (future != null) {
          futures.add(future.then((e) => entityMirror.setField(new Symbol(p.name), e)));
        }
      });

    return Future.wait(futures).then((r) => entity);
  }

  Future _saveForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.onUpdateOperation == ReferentialAction.CASCADE)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        if (fk.isManyToOne) {
          // Makes sure the parent entity has the foreign key's id up-to-date.
          data[fk.targetName] = fkData[fk.targetName];

          var future = this._count(fkResource, filters: [new Filter(fkPk.columnName, fkData[fkPk.name])]).then((count) {
            if (count == 0) {
              return this._create(fkResource, fkData);
            } else {
              return this._update(fkResource, fkData);
            }
          });

          futures.add(future);
        }
        else if (fk.isOneToMany) {
          fkData.forEach((e) {
            // Makes sure all the foreign keys have their target id correct.
            e[fk.targetName] = data[resource.primaryKeyProperty.name];

            var future = this._count(fkResource, filters: [new Filter(fkPk.columnName, e[fkPk.name])]).then((count) {
              if (count == 0) {
                return this._create(fkResource, e);
              } else {
                return this._update(fkResource, e);
              }
            });

            futures.add(future);
          });
        }

      });

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
      map[p.name] = entityMirror.getField(new Symbol(p.name)).reflectee;
    });

    resource.foreignKeyProperties.forEach((fk) {
      var fkValue = entityMirror.getField(new Symbol(fk.name)).reflectee;

      if (fkValue != null) {
        if (fk.isManyToOne) {
          map[fk.name] = this._convertFromEntity(fkValue);
        } else if (fk.isOneToMany) {
          map[fk.name] = fkValue.map((v) => this._convertFromEntity(v));
        }
      }
    });

    return map;
  }

  Map _convertDataToDatabaseData(Map data, Resource resource) {
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
