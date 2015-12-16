/// Internal library used to keep information about an `Entity` and the database table it is linked to.
library resource;

import 'dart:mirrors';
import 'package:magnetfruit_avocadorm/avocadorm.dart' show ResourceException;
import 'package:magnetfruit_entity/entity.dart';
import '../property/property.dart';

part 'resource.dart';

/// A representation of an [Entity] class and its database table informations.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// A [Resource] keeps handy all information needed to perform CRUD operations on a specific database table.
class ResourceHandler {

  List<Resource> _resources = [];

  /**
   * Creates an instance of a [Resource].
   *
   * From the specified `Entity` class, creates a [Resource] that will become the link between that `Entity` and
   * the database table.
   *
   * Throws a [ResourceException] if the `Entity` class was incorrectly coded.
   */
  void addEntity(Type entityType) {
    if (!this._resources.any((r) => r.type == entityType)) {
      this._resources.add(this._createResource(entityType));

      var variableMirrors = reflectClass(entityType).declarations.values
        .where((dm) => dm is VariableMirror)
        .map((dm) => dm as VariableMirror)
        .where((vm) => vm.metadata.any((im) => im.reflectee is Column));

      variableMirrors.forEach((vm) {
        var column = vm.metadata.firstWhere((im) => im.reflectee is Column).reflectee as Column,
            name = MirrorSystem.getName(vm.simpleName),
            type = vm.type.reflectedType;

        if (column.isManyToOneForeignKey) {
          this.addEntity(type);
        }
        else if (column.isOneToManyForeignKey) {
          this.addEntity(reflectType(type).typeArguments[0].reflectedType);
        }
        else if (column.isManyToManyForeignKey) {
          this.addEntity(reflectType(type).typeArguments[0].reflectedType);
        }
      });
    }
  }

  Resource getResource(Type entityType) {
    return this._resources.firstWhere((r) => r.type == entityType, orElse: () => null);
  }

  Resource _createResource(Type entityType) {
    var classMirror = reflectClass(entityType),
        metadata = classMirror.metadata,
        tableMirror = metadata.firstWhere((im) => im.reflectee is Table, orElse: () => null);

    if (tableMirror == null) {
      throw new ResourceException('Entity should have the Table metadata.');
    }

    var table = (tableMirror.reflectee as Table);

    var resource = new Resource();
    resource.name = MirrorSystem.getName(classMirror.simpleName);
    resource.type = entityType;
    resource.tableName = table.tableName != null && table.tableName.isNotEmpty ? table.tableName : resource.name;
    resource.properties = _convertColumnsToProperties(entityType);

    return resource;
  }


  // Converts all [Entity] properties to [Property] instances. Basically acts as a property switch to the
  // other converter methods.
  static List<Property> _convertColumnsToProperties(Type entityType) {
    var variableMirrors = reflectClass(entityType).declarations.values
      .where((dm) => dm is VariableMirror)
      .map((dm) => dm as VariableMirror)
      .where((vm) => vm.metadata.any((im) => im.reflectee is Column)).toList();

    return variableMirrors.map((vm) {
      var column = vm.metadata.firstWhere((im) => im.reflectee is Column).reflectee as Column,
          name = MirrorSystem.getName(vm.simpleName),
          type = vm.type.reflectedType;

      if (column.isPrimaryKey) {
        return _convertPrimaryKeyColumnToProperty(name, type, column);
      }
      else if (column.isManyToOneForeignKey) {
        return _convertManyToOneForeignKeyColumnToProperty(name, type, column, variableMirrors);
      }
      else if (column.isOneToManyForeignKey) {
        return _convertOneToManyForeignKeyColumnToProperty(name, type, column, variableMirrors);
      }
      else if (column.isManyToManyForeignKey) {
        return _convertManyToManyForeignKeyColumnToProperty(name, type, column, variableMirrors);
      }
      else {
        return _convertColumnToProperty(name, type, column);
      }
    }).toList();
  }

  // Converts a normal property to a [Property] instance.
  static Property _convertColumnToProperty(String name, Type type, Column column) {
    var columnName = column.name;

    if (column.name == null || column.name.isEmpty) {
      columnName = name;
    }

    return new Property(name, type, columnName);
  }

  // Converts a primary key property to a [PrimaryKeyProperty] instance.
  static Property _convertPrimaryKeyColumnToProperty(String name, Type type, Column column) {
    var columnName = column.name;

    if (column.name == null || column.name.isEmpty) {
      columnName = name;
    }

    var r = reflectType(type);
    if (!r.isSubtypeOf(reflectType(num)) && !r.isSubtypeOf(reflectType(String))) {
      throw new ResourceException('Primary keys should be a value type.');
    }

    return new PrimaryKeyProperty(name, type, columnName);
  }

  // Converts a many-to-one foreign key property to a [ForeignKeyProperty] instance.
  static Property _convertManyToOneForeignKeyColumnToProperty(String name, Type type, Column column, List<VariableMirror> variableMirrors) {
    if (type is! Type || !reflectType(type).isSubtypeOf(reflectType(Entity))) {
      throw new ResourceException('Many-to-one foreign keys must be of type Entity.');
    }

    if (!variableMirrors.any((vm) => MirrorSystem.getName(vm.simpleName) == column.targetName)) {
      //throw new ResourceException('Many-to-one foreign keys must point to a Column in the same class.');
    }

    var targetName = column.targetName;

    if (column.targetName == null || column.targetName.isEmpty) {
      targetName = '${name}Id';
    }

    return new ManyToOneForeignKeyProperty(name, type, targetName, column.recursiveSave, column.recursiveDelete);
  }

  // Converts a one-to-many foreign key property to a [ForeignKeyProperty] instance.
  static Property _convertOneToManyForeignKeyColumnToProperty(String name, Type type, Column column, List<VariableMirror> variableMirrors) {
    if (!reflectType(type).isSubtypeOf(reflectType(List))) {
      throw new ResourceException('One-to-many foreign keys must be of type List.');
    }

    // For simplicity, OneToMany's type should not be List<Entity>, but Entity.
    var subType = reflectType(type).typeArguments[0].reflectedType;

    if (subType is! Type || !reflectType(subType).isSubtypeOf(reflectType(Entity))) {
      throw new ResourceException('One-to-many foreign keys must be a list of type Entity.');
    }

    if (!reflectClass(subType).declarations.values
      .where((dm) => dm is VariableMirror)
      .map((dm) => dm as VariableMirror)
      .where((vm) => vm.metadata.any((im) => im.reflectee is Column))
      .any((vm) => MirrorSystem.getName(vm.simpleName) == column.targetName)) {
      throw new ResourceException('One-to-many foreign keys must point to a Column in the target class.');
    }

    var targetName = column.targetName;

    if (column.targetName == null || column.targetName.isEmpty) {
      targetName = '${MirrorSystem.getName(reflectType(subType).simpleName)}Id';
    }

    return new OneToManyForeignKeyProperty(name, subType, targetName, column.recursiveSave, column.recursiveDelete);
  }

  // Converts a many-to-many foreign key property to a [ForeignKeyProperty] instance.
  static Property _convertManyToManyForeignKeyColumnToProperty(String name, Type type, Column column, List<VariableMirror> variableMirrors) {
    if (!reflectType(type).isSubtypeOf(reflectType(List))) {
      throw new ResourceException('Many-to-many foreign keys must be of type List.');
    }

    // For simplicity, ManyToMany's type should not be List<Entity>, but Entity.
    var subType = reflectType(type).typeArguments[0].reflectedType;

    if (subType is! Type || !reflectType(subType).isSubtypeOf(reflectType(Entity))) {
      throw new ResourceException('Many-to-many foreign keys must be a list of type Entity.');
    }

    return new ManyToManyForeignKeyProperty(name, subType, column.junctionTableName, column.targetColumnName, column.otherColumnName, column.recursiveSave, column.recursiveDelete);
  }

}
