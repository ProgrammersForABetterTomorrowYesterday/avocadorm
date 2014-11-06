/**
 * ORM to perform CRUD operations on entities.
 *
 * The Avocadorm allows the user to perform CRUD operations by linking a database to a set of entities. They can be
 * coded to give all the information needed to operate on database tables. Since all the information is coded in the
 * entities, there is no need for additional mapping or configuration files.
 *
 * To use the Avocadorm, add a dependency to `magnetfruit_avocadorm`. You also need to choose and add a dependency
 * to a *Database Handler*, based on the type of database you use.
 *
 *     dependencies:
 *       magnetfruit_avocadorm: '>=0.1.0 <0.2.0'
 *       magnetfruit_mysql_database_handler: '>=0.1.0 <0.2.0'
 *
 * You can then import the library in your project.
 *
 *     import 'package:magnetfruit_avocadorm/avocadorm.dart';
 *     import 'package:magnetfruit_mysql_database_handler/mysql_database_handler.dart';
 *
 * Please visit the [magnetfruit](http://www.magnetfruit.com/) website for documentation, examples, and information
 * about the [avocadorm](http://www.magnetfruit.com/avocadorm/). For information about entities, and how to code
 * them, you can visit the [entity](http://www.magnetfruit.com/entity/) website. For information about database
 * handlers, including how to code one if your database of choice is not available, you can visit the
 * [database handler](http://www.magnetfruit.com/databasehandler/) website.
 */
library avocadorm;

import 'dart:async';
import 'dart:mirrors';
import 'package:magnetfruit_database_handler/database_handler.dart';
import 'package:magnetfruit_entity/entity.dart';
import 'src/resource/resource_handler.dart';

part 'exceptions/avocadorm_exception.dart';
part 'exceptions/resource_exception.dart';

/// A link to a database, and a provider of CRUD operations for entities.
///
/// The CRUD operations return `Future`s. This means the code using the result will have to be async. For example,
/// if you want to retrieve a specific employee from the database, and print his name, the `print` needs to be
/// enclosed in a `then`, as shown:
///
///     avo.readById(Employee, 1)
///       .then((employee) => print(employee.name));
///
/// See the [Dart tutorial](https://www.dartlang.org/docs/tutorials/futures/) for more information about `Future`s.
class Avocadorm {

  /// The database implementation, which handles the queries.
  DatabaseHandler _databaseHandler;

  /// The resource handler, which creates and hands out resources.
  ResourceHandler _resourceHandler = new ResourceHandler();

  /// Singleton instance of the avocadorm.
  static final Avocadorm _instance = new Avocadorm._internal();

  /**
   * Returns the instance of the singleton Avocadorm.
   *
   * The Avocadorm must be set with a `DatabaseHandler` and has to be given entities before being usable.
   */
  factory Avocadorm() {
    return _instance;
  }

  Avocadorm._internal();

  /**
   * Sets the `DatabaseHandler` that will be used to connect to a database.
   *
   * The specified database handler will be used by the Avocadorm to perform CRUD operations on a database.
   *
   * Throws an [ArgumentError] if the `DatabaseHandler` is null or invalid.
   *
   *     avo.setDatabaseHandler(dbHandler);
   */
  void setDatabaseHandler(DatabaseHandler databaseHandler) {
    if (databaseHandler == null) {
      throw new ArgumentError('Database handler must not be null.');
    }

    if (databaseHandler is! DatabaseHandler) {
      throw new ArgumentError('Database handler is of an invalid type.');
    }

    this._databaseHandler = databaseHandler;
  }

  /**
   * Adds an `Entity` library to this ORM.
   *
   * All `Entity` classes found in the specified library will be added to this ORM as `Resource`s. The library should
   * be imported to the project, for example by means of `import 'entities/entities.dart';`. Returns how many `Entity`
   * classes were added.
   *
   * Throws an [ArgumentError] if the library name is null or invalid.
   * Throws a [ResourceException] if an `Entity` class was incorectly coded.
   *
   *     avo.addEntitiesInLibrary('entities');
   */
  void addEntitiesInLibrary(String libraryName) {
    if (libraryName == null || libraryName is! String || libraryName.isEmpty) {
      throw new ArgumentError('Library name must be a non-null, non-empty String.');
    }

    var lib;

    try {
      lib = currentMirrorSystem().findLibrary(new Symbol(libraryName));
    } catch(e) {
      throw new ArgumentError('Library name must designate a valid library.');
    }

    // Looks at all the classes inside [lib], keeps only those which extends from [Entity],
    // and adds all these to this ORM.
    lib.declarations.values
      .where((dm) => dm is ClassMirror)
      .map((dm) => dm as ClassMirror)
      .where((cm) => cm.isSubtypeOf(reflectType(Entity)))
      .map((cm) => cm.reflectedType)
      .forEach((et) {
        this._addEntityResource(et);
      });
  }

  /**
   * Adds a list of `Entity` class to this ORM.
   *
   * All `Entity` classes in the specified list will be added to this ORM as `Resource`s. Returns how many `Entity`
   * classes were added.
   *
   * Throws an [ArgumentError] if the list is null or contains invalid items.
   * Throws a [ResourceException] if an `Entity` class was incorectly coded.
   *
   *     avo.addEntities([Employee, Company]);
   */
  void addEntities(List<Type> entityTypes) {
    _validateEntityTypeList(entityTypes);

    // Adds all [Entity] classes in [entityTypes] to this ORM.
    entityTypes.forEach((et) {
        this._addEntityResource(et);
      });
  }

  /**
   * Adds an `Entity` class to this ORM.
   *
   * The specified `Entity` class will be added to this ORM as a `Resource`. Returns 0 or 1, indicating whether
   * the `Entity` class was successfully added. Returns a number instead of a boolean for consistency with the
   * methods [addEntitiesInLibrary] and [addEntities].
   *
   * Throws an [ArgumentError] if the `Entity` class was null or invalid.
   * Throws a [ResourceException] if the `Entity` class was incorectly coded.
   *
   *     avo.addEntity(EmployeeType);
   */
  void addEntity(Type entityType) {
    _validateEntityType(entityType);

    this._addEntityResource(entityType);
  }

  // Converts the [Entity] class to a [Resource], and adds it to the list.
  void _addEntityResource(Type entityType) {
    this._resourceHandler.addEntity(entityType);
  }

  // Returns a value indicating whether the Avocadorm is ready to use.
  bool get isActive => this._databaseHandler != null;

  /**
   * Clears the Avocadorm from its database handler and its entities.
   *
   * This sets the database handler
   */
  void clear() {
    this._databaseHandler = null;
    this._resourceHandler = new ResourceHandler();
  }


  /**
   * Creates the specified `Entity` instance in the database.
   *
   * The `Entity` instance's primary key value will be set to null. If an `Entity` is to be created to the database
   * with the same primary key value, the [save] method should be used. Returns a `Future` containing the primary
   * key value of the new table row.
   *
   * Throws an [ArgumentError] if the `Entity` instance is null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the primary key value already exists in the
   * database.
   *
   *     var entity = new Employee('Doe', 'John');
   *     avo.create(entity).then( ... );
   */
  Future<Object> create(Entity entity) {
    _validateEntity(entity);
    _validateAvocadorm();

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
   * Creates the `Entity` specified by the [data] argument in the database.
   *
   * This is a method similar to [create], typically used when dealing with an HTTP request, which has a JSON string.
   * Usage of [create] is prefered in normal scenarios. See the [create] method for more information.
   *
   * Throws an [ArgumentError] if the `Entity` class or [data] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the primary key value already exists in the
   * database.
   *
   *     avo.createFromMap(httpRequest).then( ... );
   */
  Future<Object> createFromMap(Type entityType, Map data) {
    _validateEntityType(entityType);
    _validateDataMap(data);
    _validateAvocadorm();

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
   * Verifies how many of the specified `Entity` class there are in the database.
   *
   * Returns how many table rows of the specified `Entity` class there are. An optional list of filter can be
   * specified. Returns a `Future` containing the number of such `Entity` classes.
   *
   * Throws an [ArgumentError] if the `Entity` class is null or invalid, or if the list of `Filter` contains
   * invalid items.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     avo.count(Employee, filters: [new Filter('firstName', 'John')]).then( ... );
   */
  Future<int> count(Type entityType, {List<Filter> filters}) {
    _validateEntityType(entityType);
    _validateFilterList(filters);
    _validateAvocadorm();

    var resource = this._getResource(entityType),
        dbFilters = this._convertFiltersToDatabaseFilters(filters, resource);

    return this._count(resource, filters: dbFilters);
  }

  /**
   * Verifies whether an `Entity` class has a specific primary key value in the database.
   *
   * Returns a `Future` containing a boolean value indicating whether the specified `Entity` class can be found
   * in the database with the given primary key value.
   *
   * Throws an [ArgumentError] if the `Entity` class or [primaryKeyValue] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     avo.hasId(Employee, value).then( ... );
   */
  Future<bool> hasId(Type entityType, Object primaryKeyValue) {
    _validateEntityType(entityType);
    _validatePrimaryKeyValue(primaryKeyValue);
    _validateAvocadorm();

    var resource = this._getResource(entityType),
    pkColumn = resource.primaryKeyProperty.columnName,
    filters = [new Filter(pkColumn, primaryKeyValue)];

    return this._count(resource, filters: filters)
    .then((count) => count > 0);
  }

  /**
   * Retrieves all `Entity` instances in the database.
   *
   * Retrieves all table rows of the specified `Entity` class matching the optional list of `Filter`. Foreign keys
   * can also be retrieved by name at the same time, by specifying them in the list [foreignKeys]. Returns a `Future`
   * containing a list of `Entity` instances.
   *
   * Throws an [ArgumentError] if the `Entity` class or [primaryKeyValue] are null or invalid, or the list of `Filter`
   * contains invalid items.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     // Retrieves all employees where firstName == 'John'.
   *     avo.read(Employee, filters: [new Filter('firstName', 'John')]).then( ... );
   *
   *     // Retrieves all companies, and their 'employees' lists.
   *     avo.read(Company, foreignKeys: ['employees.employeeType']).then( ... );
   *
   * In the example above, the `'employees.employeeType'` asks the Avocadorm to retrieve the `Company`'s `employees`
   * property for every retrieved company, and the `employeeType` property for all retrieved employee in `employees`.
   */
  Future<List<Entity>> read(Type entityType, {List<Filter> filters, List<String> foreignKeys}) {
    _validateEntityType(entityType);
    _validateFilterList(filters);
    _validateAvocadorm();

    var resource = this._getResource(entityType),
        dbFilters = this._convertFiltersToDatabaseFilters(filters, resource);

    return this._read(resource, filters: dbFilters, foreignKeys: foreignKeys);
  }

  /**
   * Retrieves the `Entity` instance matching the specified primary key value.
   *
   * Retrieves the table row of the specified `Entity` class matching the given primary key value. Foreign keys
   * can also be retrieved at the same time, by specifying them in the list [foreignKeys]. Returns a `Future`
   * containing an `Entity` instance, or `null` if no matching `Entity` could be found.
   *
   * Throws an [ArgumentError] if the `Entity` class or [primaryKeyValue] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     avo.readById(Employee, value, foreignKeys: ['answersTo']).then( ... );
   */
  Future<Entity> readById(Type entityType, Object primaryKeyValue, {List<String> foreignKeys}) {
    _validateEntityType(entityType);
    _validatePrimaryKeyValue(primaryKeyValue);
    _validateAvocadorm();

    var resource = this._getResource(entityType),
        pkColumn = resource.primaryKeyProperty.columnName,
        filters = [new Filter(pkColumn, primaryKeyValue)];

    return this._read(resource, filters: filters, foreignKeys: foreignKeys, limit: 1)
      .then((entities) => entities.length > 0 ? entities.first : null);
  }

  /**
   * Updates the specified `Entity` instance in the database.
   *
   * Updates the intended table row with the values specified in the `Entity` instance. A matching primary
   * key value must be found. Returns a `Future` containing the primary key value of the `Entity`.
   *
   * Throws an [ArgumentError] if the `Entity` instance is null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the table does not contain a matching primary
   * key value.
   *
   *     avo.readById(Employee, 2).then((employee) {
   *       employee.isFired = true;
   *       avo.update(employee).then((id) => print('Done!'));
   *     });
   */
  Future<Object> update(Entity entity) {
    _validateEntity(entity);
    _validateAvocadorm();

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
   * Updates an `Entity` class with the values from [data].
   *
   * This is a method similar to [update], typically used when dealing with an HTTP request, which has a JSON string.
   * Usage of [update] is prefered in normal scenarios. See the [update] method for more information.
   *
   * Throws an [ArgumentError] if the `Entity` class or [data] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the table does not contain a matching primary
   * key value.
   *
   *     avo.updateFromMap(Company, httpRequest).then( ... );
   */
  Future<Object> updateFromMap(Type entityType, Map data) {
    _validateEntityType(entityType);
    _validateDataMap(data);
    _validateAvocadorm();

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
   * Creates or updates the specified `Entity` instance in the database.
   *
   * Depending on whether a table row can be found with the matching primary key value, this method will create
   * or update the specified `Entity`. Contrary to the [create] method, creating an entity with the [save] method
   * will keep the specified primary key value (if possible by the database). Returns a `Future` containing the
   * primary key value of the saved `Entity` instance.
   *
   * Throws an [ArgumentError] if the `Entity` instance is null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     var entity = new Employee('Doe', 'Jane);
   *     avo.save(entity).then( ... );
   */
  Future<Object> save(Entity entity) {
    _validateEntity(entity);
    _validateAvocadorm();

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
   * Creates or updates an `Entity` class with the values from [data].
   *
   * This is a method similar to [save], typically used when dealing with an HTTP request, which has a JSON string.
   * Usage of [save] is prefered in normal scenarios. See the [save] method for more information.
   *
   * Throws an [ArgumentError] if the `Entity` class or [data] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active.
   *
   *     avo.saveFromMap(Employee, httpRequest).then( ... );
   */
  Future<Object> saveFromMap(Type entityType, Map data) {
    _validateEntityType(entityType);
    _validateDataMap(data);
    _validateAvocadorm();

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
   * Deletes the table row matching the primary key in the specified `Entity` instance. A matching primary key value
   * must be found. Returns an empty `Future`.
   *
   * Throws an [ArgumentError] if the `Entity` instance is null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the primary key value is not found in the
   * database.
   *
   *     avo.delete(myEmployee).then( ... );
   */
  Future delete(Entity entity) {
    _validateEntity(entity);
    _validateAvocadorm();

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
   * Deletes the matching `Entity` class from the database.
   *
   * Deletes the table row matching the `Entity` class with the specified primary key value. A matching primary key
   * value must be found. Returns an empty `Future`.
   *
   * Throws an [ArgumentError] if the `Entity` class or [primaryKeyValue] are null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the primary key value is not found in the
   * database.
   *
   *     avo.deleteById(Employee, 23).then( ... );
   */
  Future deleteById(Type entityType, Object primaryKeyValue) {
    _validateEntityType(entityType);
    _validatePrimaryKeyValue(primaryKeyValue);
    _validateAvocadorm();

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

  /**
   * Deletes the matching `Entity` class from the database.
   *
   * This is a method similar to [delete], typically used when dealing with an HTTP request, which has a JSON string.
   * Usage of [delete] is prefered in normal scenarios. See the [delete] method for more information.
   *
   * Throws an [ArgumentError] if the `Entity` instance is null or invalid.
   * Throws an [AvocadormException] if the [Avocadorm] is not active, or the primary key value is not found in the
   * database.
   *
   *     avo.deleteFromMap(httpRequest).then( ... );
   */
  Future deleteFromMap(Type entityType, Map data) {
    _validateEntityType(entityType);
    _validateDataMap(data);
    _validateAvocadorm();

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


  // Creates an [Entity] in the database.
  Future<Object> _create(Resource resource, Map data) {
    var pkColumn = resource.primaryKeyProperty.columnName,
        columns = resource.simpleProperties.map((p) => p.columnName).toList();

    var pkValue;

    return this._saveManyToOneForeignKeys(resource, data)
      .then((pkMaps) {
        // Updates the many-to-one foreign keys' primary key value in the parent entity.
        pkMaps.forEach((pkMap) {
          data[pkMap['target']] = pkMap['pkValue'];
        });

        var dbData = this._convertDataToDatabaseData(data, resource);

        return this._databaseHandler.create(resource.tableName, pkColumn, columns, dbData);
      })
      .then((pk) {
        data[pkColumn] = pkValue = pk;

        // Updates the parent entity's primary key value in its one-to-many foreign keys.
        resource.foreignKeyProperties
          .where((fk) => fk.isOneToMany)
          .where((fk) => data[fk.name] != null)
          .forEach((fk) {
            var fkResource = this._getResource(fk.type);

            // This requires an entity wrapper in order to determine which many-to-one fk to update, in
            // the case when multiple fks have the same entity type.
            data[fk.name].forEach((d) {
              fkResource.foreignKeyProperties
                .where((sfk) => sfk.isManyToOne)
                .where((sfk) => sfk.type == resource.type)
                .where((sfk) => d[sfk.targetName] != null)
                .forEach((sfk) {
                  d[sfk.targetName] = pk;
                });
            });
          });

        return this._saveOneToManyForeignKeys(resource, data);
      })
      .then((r) {
        return this._saveManyToManyForeignKeys(resource, data);
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
        columns = resource.simpleProperties.map((p) => p.columnName).toList();

    var pkValue;

    return this._saveManyToOneForeignKeys(resource, data)
      .then((pkMaps) {
        // Updates the many-to-one foreign keys' primary key value in the parent entity.
        pkMaps.forEach((pkMap) {
          data[pkMap['target']] = pkMap['pkValue'];
        });

        var dbData = this._convertDataToDatabaseData(data, resource);

        return this._databaseHandler.update(resource.tableName, pkColumn, columns, dbData);
      })
      .then((pk) {
        data[pkColumn] = pkValue = pk;

        // Updates the parent entity's primary key value in its one-to-many foreign keys.
        resource.foreignKeyProperties
          .where((fk) => fk.isOneToMany)
          .where((fk) => data[fk.name] != null)
          .forEach((fk) {
            var fkResource = this._getResource(fk.type);

            // This requires an entity wrapper in order to determine which many-to-one fk to update, in
            // the case when multiple fks have the same entity type.
            data[fk.name].forEach((d) {
              fkResource.foreignKeyProperties
                .where((sfk) => sfk.isManyToOne)
                .where((sfk) => sfk.type == resource.type)
                .where((sfk) => d[sfk.targetName] != null)
                .forEach((sfk) {
                  d[sfk.targetName] = pk;
                });
            });
          });

        return this._saveOneToManyForeignKeys(resource, data);
      })
      .then((r) {
        return this._saveManyToManyForeignKeys(resource, data);
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
    var resource = this._resourceHandler.getResource(entityType);

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
          var targetResource = this._getResource(p.type),
              targetColumn = targetResource.simpleProperties.firstWhere((tp) => tp.name == p.targetName).columnName,
              targetValue = entityMirror.getField(new Symbol(resource.primaryKeyProperty.name)).reflectee;

          future = this._read(
              targetResource,
              filters: [new Filter(targetColumn, targetValue)],
              foreignKeys: _traverseForeignKeyList(foreignKeys, p.name));
        }
        else if (p.isManyToMany) {
          var targetPkValue = entityMirror.getField(new Symbol(resource.primaryKeyProperty.name)).reflectee,
              filters = [new Filter(p.targetColumnName, targetPkValue) ];

          // Calling the database handler directly because the junction table is not a resource.
          future = this._databaseHandler.read(p.junctionTableName, [p.otherColumnName], filters)
            .then((entities) {
              var subFutures = [],
                  targetResource = this._getResource(p.type),
                  targetColumn = targetResource.primaryKeyProperty.columnName;

              entities.forEach((e) {
                var targetValue = e[p.otherColumnName];

                var subFuture = this._read(
                  targetResource,
                  filters: [new Filter(targetColumn, targetValue)],
                  foreignKeys: _traverseForeignKeyList(foreignKeys, p.name))
                  .then((e2) => e2.first);

                subFutures.add(subFuture);
              });

              return Future.wait(subFutures);
            });
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
      .where((fk) => fk.recursiveSave)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        var future;

        if (fk.isManyToOne) {
          // Makes sure the parent entity has the foreign key's id up-to-date.
          data[fk.targetName] = fkData[fk.targetName];

          future = this._count(fkResource, filters: [new Filter(fkPk.columnName, fkData[fkPk.name])])
            .then((count) {
              if (count == 0) {
                return this._create(fkResource, fkData);
              } else {
                return this._update(fkResource, fkData);
              }
            });
        }
        else if (fk.isOneToMany) {
          fkData.forEach((e) {
            // Makes sure all the foreign keys have their target id correct.
            e[fk.targetName] = data[resource.primaryKeyProperty.name];

            future = this._count(fkResource, filters: [new Filter(fkPk.columnName, e[fkPk.name])])
              .then((count) {
                if (count == 0) {
                  return this._create(fkResource, e);
                } else {
                  return this._update(fkResource, e);
                }
              });
          });
        }
        else if (fk.isManyToMany) {
          fkData.forEach((e) {
            // Adds a row in the junction table associated with the current fk pk, and its parent pk.

            var fkPkValue;

            future = this._count(fkResource, filters: [new Filter(fkPk.columnName, e[fkPk.name])])
              .then((count) {
                if (count == 0) {
                  return this._create(fkResource, e);
                } else {
                  return this._update(fkResource, e);
                }
              })
              .then((pkValue) {
                fkPkValue = pkValue;

                var filters = [
                    new Filter(fk.targetColumnName, data[resource.primaryKeyProperty.name]),
                    new Filter(fk.otherColumnName, fkPkValue)
                ];

                return this._databaseHandler.count(fk.junctionTableName, filters);
              }).then((count) {
                if (count == 0) {
                  // Adds the row in the junction table.
                  var map = {};
                  map[fk.targetColumnName] = data[resource.primaryKeyProperty.name];
                  map[fk.otherColumnName] = fkPkValue;

                  return this._databaseHandler.create(fk.junctionTableName, fk.targetColumnName, [fk.otherColumnName], map);
                }

                return new Future.value(null);
              });
          });
        }

        futures.add(future);
    });

    return Future.wait(futures);
  }

  // Saves the many-to-one foreign keys of the specified data.
  Future _saveManyToOneForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.isManyToOne)
      .where((fk) => fk.recursiveSave)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        // Makes sure the parent entity has the foreign key's id up-to-date.
        data[fk.targetName] = fkData[fk.targetName];

        var future = this._count(fkResource, filters: [new Filter(fkPk.columnName, fkData[fkPk.name])])
          .then((count) {
            if (count == 0) {
              return this._create(fkResource, fkData);
            } else {
              return this._update(fkResource, fkData);
            }
          })
          .then((pk) => {'target': fk.targetName, 'pkValue': pk});

        futures.add(future);
      });

    return Future.wait(futures);
  }

  // Saves the one-to-many foreign keys of the specified data.
  Future _saveOneToManyForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.isOneToMany)
      .where((fk) => fk.recursiveSave)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        fkData.forEach((e) {
          // Makes sure all the foreign keys have their target id correct.
          e[fk.targetName] = data[resource.primaryKeyProperty.name];

          var future = this._count(fkResource, filters: [new Filter(fkPk.columnName, e[fkPk.name])])
            .then((count) {
              if (count == 0) {
                return this._create(fkResource, e);
              } else {
                return this._update(fkResource, e);
              }
            });

          futures.add(future);
        });

      });

    return Future.wait(futures);
  }

  // Saves the many-to-many foreign keys of the specified data.
  Future _saveManyToManyForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.isManyToMany)
      .where((fk) => fk.recursiveSave)
      .where((fk) => data[fk.name] != null)
      .forEach((fk) {
        var fkResource = this._getResource(fk.type),
            fkPk = fkResource.primaryKeyProperty,
            fkData = data[fk.name];

        fkData.forEach((e) {
          // Adds a row in the junction table associated with the current fk pk, and its parent pk.

          var fkPkValue;

          var future = this._count(fkResource, filters: [new Filter(fkPk.columnName, e[fkPk.name])])
            .then((count) {
              if (count == 0) {
                return this._create(fkResource, e);
              } else {
                return this._update(fkResource, e);
              }
            })
            .then((pkValue) {
              fkPkValue = pkValue;

              var filters = [
                  new Filter(fk.targetColumnName, data[resource.primaryKeyProperty.name]),
                  new Filter(fk.otherColumnName, fkPkValue)
              ];

              return this._databaseHandler.count(fk.junctionTableName, filters);
            }).then((count) {
              if (count == 0) {
                // Adds the row in the junction table.
                var map = {};
                map[fk.targetColumnName] = data[resource.primaryKeyProperty.name];
                map[fk.otherColumnName] = fkPkValue;

                return this._databaseHandler.create(fk.junctionTableName, fk.targetColumnName, [fk.otherColumnName], map);
              }

              return new Future.value(null);
            });

          futures.add(future);
        });
      });

    return Future.wait(futures);
  }

  // Recursively deletes the [Entity] and its foreign keys.
  Future _deleteForeignKeys(Resource resource, Map data) {
    var futures = [];

    resource.foreignKeyProperties
      .where((fk) => fk.recursiveDelete)
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
        else if (fk.isManyToMany) {
          var future = new Future.value(fkData)
            .then((entities) {
              if (entities != null) {
                return entities;
              }
              else {
                var targetPkValue = data[resource.primaryKeyProperty.name],
                    filters = [new Filter(fk.targetColumnName, targetPkValue) ];

                // Calling the database handler directly because the junction table is not a resource.
                return this._databaseHandler.read(fk.junctionTableName, [fk.otherColumnName], filters).then((entities) {

                  var subFutures = [],
                      otherPk = fkResource.primaryKeyProperty.columnName;

                  entities.forEach((e) {
                    var targetValue = e[fk.otherColumnName];

                    var subFuture = this._read(fkResource, filters: [new Filter(otherPk, targetValue)])
                      .then((e2) => e2 != null && e2.length > 0 ? e2.first : null);

                    subFutures.add(subFuture);
                  });

                  return Future.wait(subFutures).then((entities) => entities.where((e) => e != null));
                });
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
        } else if (fk.isOneToMany || fk.isManyToMany) {
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
        throw new AvocadormException('Property ${f.name} could not be found on ${resource.name}.');
      }

      f.name = property.columnName;

      return f;
    }).where((f) => f != null).toList();
  }


  // Validates if the Avocadorm is active.
  void _validateAvocadorm() {
    if (!this.isActive) {
      throw new AvocadormException('The Avocadorm must have a database handler defined.');
    }
  }

  // Validates an [Entity] argument.
  static void _validateEntity(Entity entity) {
    if (entity == null) {
      throw new ArgumentError('Entity must not be null.');
    }

    if (entity is! Entity) {
      throw new ArgumentError('Entity is of an invalid type.');
    }
  }

  // Validates an [Entity] type argument.
  static void _validateEntityType(Type entityType) {
    if (entityType == null) {
      throw new ArgumentError('Entity type must not be null.');
    }

    if (entityType is! Type || !reflectType(entityType).isSubtypeOf(reflectType(Entity))) {
      throw new ArgumentError('Entity type is of an invalid type.');
    }
  }

  // Validates a list of [Entity] type argument.
  static void _validateEntityTypeList(List<Type> entityTypes) {
    if (entityTypes == null) {
      throw new ArgumentError('List of entity type must not be null.');
    }

    if (entityTypes is! Iterable) {
      throw new ArgumentError('List of entity type is of an invalid type.');
    }

    entityTypes.forEach((et) => _validateEntityType(et));
  }

  // Validates a primary key value argument.
  static void _validatePrimaryKeyValue(Object primaryKeyValue) {
    if (primaryKeyValue == null) {
      throw new ArgumentError('Primary key value must not be null.');
    }

    if (primaryKeyValue != null && primaryKeyValue is! num && primaryKeyValue is! String) {
      throw new ArgumentError('Primary key value is of an invalid type.');
    }
  }

  // Validates a [data] [Map] argument.
  static void _validateDataMap(Map data) {
    if (data == null) {
      throw new ArgumentError('Data map must not be null.');
    }

    if (data is! Map) {
      throw new ArgumentError('Data map is of an invalid type.');
    }
  }

  // Validates a [Filter] argument.
  static void _validateFilter(Filter filter) {
    if (filter == null) {
      throw new ArgumentError('Filter must not be null.');
    }

    if (filter is! Filter) {
      throw new ArgumentError('Filter is of an invalid type.');
    }
  }

  // Validates a list of [Filter] argument. It is assumed to be nullable.
  static void _validateFilterList(List<Filter> filters) {
    if (filters == null) {
      return;
    }

    if (filters is! Iterable) {
      throw new ArgumentError('List of filter is of an invalid type.');
    }

    filters.forEach((f) => _validateFilter(f));
  }

  // Moves up through the list of foreign keys, eliminating unwanted foreign keys.
  static List<String> _traverseForeignKeyList(List<String> foreignKeys, String propertyName) {
    var traversedForeignKeys = foreignKeys
      .where((fk) => fk == propertyName || fk.startsWith('${propertyName}.'))
      .map((fk) => fk.substring(propertyName.length))
      .where((fk) => fk.isNotEmpty)
      .map((fk) => _trimLeft(fk, '.')).toList();

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
