library magnetfruit_avocadorm;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';
import 'package:magnetfruit_entity/entity.dart';

part 'database_handler/database_handler.dart';
part 'database_handler/filter.dart';
part 'exceptions/avocadorm_exception.dart';
part 'exceptions/resource_exception.dart';
part 'src/property/foreign_key_property.dart';
part 'src/property/primary_key_property.dart';
part 'src/property/property.dart';
part 'src/resource/resource.dart';

/// A lightweight ORM linking [Entity] classes to a [DatabaseHandler].
class Avocadorm {

  /// The database implementation, which handles the queries.
  DatabaseHandler _databaseHandler;

  /// The list of [Entity] classes that were added to this ORM.
  List<Resource> _resources;

  /**
   * Creates an instance of an ORM.
   *
   * This avocadorm is linked to the specified [DatabaseHandler], starts empty of [Entity]s, and will have to be
   * populated before being usable.
   * Throws an [ArgumentError] if the [DatabaseHandler] is null or invalid.
   */
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

  /**
   * Adds a library of [Entity] class to this ORM.
   *
   * All [Entity] classes found in specified library will be added to this ORM as [Resource]s. Library should be
   * imported to the project using Avocadorm. Returns how many [Entity] classes were added.
   * Throws an [ArgumentError] if the library name is null or invalid.
   * Throws a [ResourceException] if an [Entity] class was incorectly coded.
   *
   *     avo.addEntitiesInLibrary('entities');
   */
  int addEntitiesInLibrary(String libraryName) {
    if (libraryName == null) {
      throw new ArgumentError('Argument \'libraryName\' must not be null.');
    }

    if (libraryName is! String) {
      throw new ArgumentError('Argument \'libraryName\' must be a String.');
    }

    if (libraryName.isEmpty) {
      throw new ArgumentError('Argument \'libraryName\' must not be empty.');
    }

    LibraryMirror lib;

    try {
      lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));
    } catch(e) {
      throw new ArgumentError('Argument \'libraryName\' must designate a valid library name.');
    }

    var count = 0;

    // Looks at all the classes inside [lib], keeps only those which extends from [Entity],
    // and adds all these to this ORM.
    lib.declarations.values
      .where((dm) => dm is ClassMirror)
      .map((dm) => dm as ClassMirror)
      .where((cm) => cm.isSubtypeOf(reflectType(Entity)))
      .map((cm) => cm.reflectedType)
      .forEach((et) {
        if (this._addEntityResource(et)) {
          // Keeps count of how many [Entity] classes were added.
          count++;
        }
      });

    return count;
  }

  /**
   * Adds a list of [Entity] class to this ORM.
   *
   * All [Entity] classes in the specified list will be added to this ORM as [Resource]s. Returns how many [Entity]
   * classes were added.
   * Throws an [ArgumentError] if the list is null or contains invalid items.
   * Throws a [ResourceException] if an [Entity] class was incorectly coded.
   *
   *     avo.addEntities([Employee, Company]);
   */
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

    // Adds all [Entity] classes in [entityTypes] to this ORM.
    entityTypes.forEach((et) {
        if (this._addEntityResource(et)) {
          // Keeps count of how many [Entity] classes were added.
          count++;
        }
      });

    return count;
  }

  /**
   * Adds an [Entity] class to this ORM.
   *
   * The specified [Entity] class will be added to this ORM as a [Resource]. Returns 0 or 1, indicating whether
   * the [Entity] class was successfully added. Returns a number instead of a boolean for consistency with the
   * methods [addEntitiesInLibrary] and [addEntities].
   * Throws an [ArgumentError] if the [Entity] class was null or invalid.
   * Throws a [ResourceException] if the [Entity] class was incorectly coded.
   *
   *     avo.addEntity(EmployeeType);
   */
  int addEntity(Type entityType) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity class.');
    }

    return this._addEntityResource(entityType) ? 1 : 0;
  }

  // Converts the [Entity] class to a [Resource], and adds it to the list.
  bool _addEntityResource(Type entityType) {
    this._resources.add(new Resource(entityType));

    return true;
  }


  /**
   * Creates the specified [Entity] instance in the database.
   *
   * The [Entity] instance's primary key value will be set to null. If an [Entity] is to be saved to the database
   * with the same primary key value, the [save] method should be used. Returns a [Future] containing the primary
   * key value of the new table row.
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   * Throws an [AvocadormException] if the primary key value already exists in the database.
   *
   *     var entity = new Employee('Doe', 'John');
   *     avo.create(entity);
   */
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

    // The create() method makes sure the primary key value is not kept.
    data[pk.name] = null;

    return this._count(resource, filters: filters).then((count) {
      if (count > 0) {
        throw new AvocadormException('Can not create entity - primary key value is already in the database.');
      }

      return this._create(resource, data);
    });
  }

  /**
   * Creates the [Entity] specified by the [data] [Map] argument in the database.
   *
   * The [data] argument is a [Map] with the same properties as the specified [Entity] class. This [Map] will
   * typically be based on a JSON, and usage of the [create] method is prefered. The primary key value will be set
   * to null. Returns a [Future] containing the primary key value of the new table row.
   * Throws an [ArgumentError] if the [Entity] class or [data] [Map] are null or invalid.
   * Throws an [AvocadormException] if the primary key value already exists in the database.
   *
   *     avo.createFromMap(httpResponse);
   */
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

    // The createFromMap() method makes sure the primary key value is not kept.
    data[pk.name] = null;

    return this._count(resource, filters: filters).then((count) {
      if (count > 0) {
        throw new AvocadormException('Can not create entity - primary key value is already in the database.');
      }

      return this._create(resource, data);
    });
  }

  /**
   * Verifies the presence of the specified [Entity] class having a specific primary key value in the database.
   *
   * Returns a [Future] containing a boolean value indicating whether the specified [Entity] class can be found
   * in the database with the given primary key value.
   * Throws an [ArgumentError] if the [Entity] class or [primaryKeyValue] are null or invalid.
   *
   *     avo.hasId(Employee, value);
   */
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

  /**
   * Verifies how many of the specified [Entity] class there are in the database.
   *
   * Returns how many table rows of the specified [Entity] class there are. An optional list of filter can be
   * specified. Returns a [Future] containing the number of such [Entity] classes.
   * Throws an [ArgumentError] if the [Entity] class or [primaryKeyValue] are null or invalid.
   * Throws an [ArgumentError] if the list of [Filter] contains invalid items.
   *
   *     avo.count(Employee, filters: [new Filter('firstName', 'John')]);
   */
  Future<int> count(Type entityType, {List<Filter> filters}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    var resource = this._getResource(entityType),
        dbFilters = this._convertFiltersToDatabaseFilters(filters, resource);

    return this._count(resource, filters: dbFilters);
  }

  /**
   * Retrieves all [Entity] instances in the database.
   *
   * Retrieves all table rows of the specified [Entity] class matching the optional list of [Filter]. Foreign keys
   * can also be retrieved at the same time, by specifying them in the list [foreignKeys]. Returns a [Future]
   * containing a list of [Entity] instances.
   * Throws an [ArgumentError] if the [Entity] class or [primaryKeyValue] are null or invalid.
   * Throws an [ArgumentError] if the list of [Filter] contains invalid items.
   *
   *     avo.readAll(Employee, filters: [new Filter('firstName', 'John')]);
   *
   *     avo.readAll(Company, foreignKeys: ['employees']);
   */
  Future<List<Entity>> readAll(Type entityType, {List<Filter> filters, List<String> foreignKeys}) {
    if (entityType == null) {
      throw new ArgumentError('Argument \'entityType\' must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Argument \'entityType\' should be an Entity.');
    }

    var resource = this._getResource(entityType),
        dbFilters = this._convertFiltersToDatabaseFilters(filters, resource);

    return this._read(resource, filters: dbFilters, foreignKeys: foreignKeys);
  }

  /**
   * Retrieves the [Entity] instance matching the specified primary key value.
   *
   * Retrieves the table row of the specified [Entity] class matching the given primary key value. Foreign keys
   * can also be retrieved at the same time, by specifying them in the list [foreignKeys]. Returns a [Future]
   * containing an [Entity] instance.
   * Throws an [ArgumentError] if the [Entity] class or [primaryKeyValue] are null or invalid.
   *
   *     avo.readById(Employee, value, foreignKeys: ['answersTo']);
   */
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

  /**
   * Updates the specified [Entity] instance in the database.
   *
   * Updates the intended table row with the values specified in the [Entity] instance. A matching primary
   * key value must be found. Returns a [Future] containing the primary key value of the [Entity].
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   * Throws an [AvocadormException] if the table does not contain a matching primary key value.
   *
   *     avo.readById(Employee, 2).then((employee) {
   *       employee.isFired = true;
   *       avo.update(employee).then((id) => print('Done!'));
   *     });
   */
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

  /**
   * Updates an [Entity] class with the values from [data].
   *
   * Updates the intended table row with the values specified in the [data] [Map]. This is a helper method, and
   * as such, the [update] method is the prefered way to update if not dealing with JSON. Returns a [Future]
   * containing the primary key value of the [Entity].
   * Throws an [ArgumentError] if the [Entity] class or [data] [Map] are null or invalid.
   * Throws an [AvocadormException] if the table does not contain a matching primary key value.
   *
   *     avo.updateFromMap(Company, httpResponse);
   */
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

  /**
   * Creates or updates the specified [Entity] instance in the database.
   *
   * Depending on whether a table row can be found with the matching primary key value, this method will create
   * or update the specified [Entity]. Returns a [Future] containing the primary key value of the saved [Entity]
   * instance.
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   *
   *     var entity = new Employee('Doe', 'Jane);
   *     avo.save(entity);
   */
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

  /**
   * Creates or updates an [Entity] class with the values from [data].
   *
   * Depending on whether a table row can be found with the matching primary key value, this method will create
   * or update the specified [Entity] class with the values from the [data] [Map]. This is a helper method, and
   * as such, the [save] method is the prefered way to save if not dealing with JSON. Returns a [Future] containing
   * the primary key value of the [Entity].
   * Throws an [ArgumentError] if the [Entity] class or [data] [Map] are null or invalid.
   *
   *     avo.saveFromMap(modifiedEmployee);
   */
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

  /**
   * Deletes the specified entity from the database.
   *
   * Deletes the table row matching the primary key in the specified [Entity] instance. Returns an empty [Future].
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   * Throws an [AvocadormException] if the primary key value is not found in the database.
   *
   *     avo.delete(myEmployee);
   */
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

      return this._delete(resource, this._convertFromEntity(entity));
    });
  }

  /**
   * Deletes the matching [Entity] class from the database.
   *
   * Deletes the table row matching the [Entity] class with the primary key value in the [data] [Map]. Returns an
   * empty [Future].
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   * Throws an [AvocadormException] if the primary key value is not found in the database.
   *
   *     avo.deleteFromMap(httpResponse);
   */
  Future deleteFromMap(Type entityType, Map data) {
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
        throw new AvocadormException('Can not delete entity - primary key value is not in the database.');
      }

      return this._delete(resource, data);
    });
  }

  /**
   * Deletes the matching [Entity] class from the database.
   *
   * Deletes the table row matching the [Entity] class with the specified primary key value. Returns an empty
   * [Future].
   * Throws an [ArgumentError] if the [Entity] instance is null or invalid.
   * Throws an [AvocadormException] if the primary key value is not found in the database.
   *
   *     avo.deleteById(Employee, 23);
   */
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

    return this._read(resource, filters: filters).then((entities) {
      if (entities.length == 0) {
        throw new AvocadormException('Can not delete entity - primary key value is not in the database.');
      }

      return this._delete(resource, this._convertFromEntity(entities.first));
    });
  }


  // Creates an [Entity] in the database.
  Future<Object> _create(Resource resource, Map data) {
    var pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList(),
        dbData = this._convertDataToDatabaseData(data, resource);

    var pkValue;

    return this._databaseHandler.create(resource.tableName, pkColumn, columns, dbData)
      .then((pk) {
        pkValue = pk;
        return this._saveForeignKeys(resource, data);
      })
      .then((r) {
        dbData = this._convertDataToDatabaseData(data, resource);
        dbData[pkColumn] = pkValue;
        return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData);
      })
      .then((r) => pkValue);
}

  // Counts [Entity]s in the database.
  Future<int> _count(Resource resource, {List<Filter> filters}) {
    return this._databaseHandler.count(resource.tableName, filters);
  }

  // Reads [Entity]s in the database.
  Future<List<Entity>> _read(Resource resource, {List<Filter> filters, List<String> foreignKeys, int limit}) {
    var columns = resource.simpleAndPrimaryKeyProperties.map((p) => p.columnName).toList();

    return this._databaseHandler.read(resource.tableName, columns, filters, limit)
      .then((entities) => entities.map((e) => this._convertToEntity(e, resource)))
      .then((entities) => Future.wait(entities.map((e) => _retrieveForeignKeys(e, foreignKeys))));
  }

  // Updates an [Entity] in the database.
  Future<Object> _update(Resource resource, Map data) {
    var pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList(),
        dbData = this._convertDataToDatabaseData(data, resource);

    var pkValue;

    return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData)
      .then((pk) {
        pkValue = pk;
        this._saveForeignKeys(resource, data);
      })
      .then((r) {
        dbData =  this._convertDataToDatabaseData(data, resource);
        return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData);
      })
      .then((r) => pkValue);
  }

  // Deletes an [Entity] in the database.
  Future _delete(Resource resource, Map data) {
    var pk = resource.primaryKeyProperty,
        pkColumn = pk.columnName,
        pkValue = data[pk.name],
        filters = [new Filter(pkColumn, pkValue)];

    return this._deleteForeignKeys(resource, data)
      .then((r) => this._databaseHandler.delete(resource.tableName, filters));
  }


  // Finds the [Resource] instance linked to the specified [Entity] class.
  Resource _getResource(Type entityType) {
    var resource = this._resources.firstWhere((r) => r.type == entityType, orElse: () => null);

    if (resource == null) {
      throw new AvocadormException('Resource not found for entity ${entityType}.');
    }

    return resource;
  }

  // Recursively retrieves the [Entity]'s specified foreign keys.
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
              foreignKeys: _traverseForeignKeyList(foreignKeys, p.name),
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
              foreignKeys: _traverseForeignKeyList(foreignKeys, p.name));
        }

        if (future != null) {
          futures.add(future.then((e) => entityMirror.setField(new Symbol(p.name), e)));
        }
      });

    return Future.wait(futures).then((r) => entity);
  }

  // Recursively saves the [Entity] and its foreign keys.
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

  // Recursively deletes the [Entity] and its foreign keys.
  Future _deleteForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.onDeleteOperation == ReferentialAction.CASCADE)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        if (fk.isManyToOne && data[fk.targetName] != null) {
          var future = new Future.value(fkData)
            .then((entity) {
              return entity != null
                ? [entity]
                : this._read(fkResource, filters: [new Filter(fkPk.columnName, data[fk.targetName])]);
            })
            .then((entities) => this._delete(fkResource, this._convertFromEntity(entities.first)));

          futures.add(future);
        }
        else if (fk.isOneToMany) {
          var future = new Future.value(fkData)
            .then((entities) {
              if (entities != null) {
                return entities;
              }
              else {
                var fkTarget = fkResource.simpleProperties.firstWhere((p) => p.name == fk.targetName).columnName,
                    pk = resource.primaryKeyProperty.name;

                return this._read(fkResource, filters: [new Filter(fkTarget, data[pk])]);
              }
            })
            .then((entities) {
              entities.forEach((entity) {
                this._delete(fkResource, this._convertFromEntity(entity));
              });
            });

          futures.add(future);
        }
      });

    return Future.wait(futures);
  }


  // Converts a [data] [Map] to an [Entity] instance.
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

  // Converts an [Entity] instance to a [Map].
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

  // Converts a [data] [Map] to a database-oriented [Map].
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

  // Converts a list of [Filter] to a database-oriented list of [Filter].
  List<Filter> _convertFiltersToDatabaseFilters(List<Filter> filters, Resource resource) {
    if (filters == null) {
      return null;
    }

    var properties = resource.simpleAndPrimaryKeyProperties;

    return filters.map((f) {
      var property = properties.firstWhere((p) => p.name == f.name, orElse: () => null);

      if (property == null) {
        throw new ArgumentError('Property ${f.name} could not be found on ${resource.name}.');
      }

      f.name = property.columnName;

      return f;
    }).where((f) => f != null).toList();
  }

  // Moves up through the list of foreign keys, eliminating unwanted foreign keys.
  static List<String> _traverseForeignKeyList(List<String> foreignKeys, String propertyName) {
    var traversedForeignKeys = foreignKeys
      .where((fk) => fk == propertyName || fk.startsWith('${propertyName}.'))
      .map((fk) => fk.substring(propertyName.length))
      .where((fk) => fk.isNotEmpty)
      .map((fk) => _trimLeft(fk, '.'));

    return _distinct(traversedForeignKeys);
  }

  // Removes the left-most [trimChar] character from the [input] string.
  static String _trimLeft(String input, String trimChar) {
    int pos = 0;

    while (pos < input.length && input[pos] == trimChar) {
      pos++;
    }

    return input.substring(pos);
  }

  // Removes duplicate items from the [input] list.
  static List _distinct(List input) {
    var output = [];

    input.forEach((i) {
      if (!output.contains(i)) {
        output.add(i);
      }
    });

    return output;
  }
}
