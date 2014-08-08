part of magnetfruit_avocadorm;

class Resource {
  String name;
  Type type;
  String tableName;
  List<Property> properties;
  int httpMethods;

  Property get primaryKeyProperty => this.properties.firstWhere((f) => f is PrimaryKeyProperty, orElse: null);

  List<Property> get simpleProperties => this.properties.where((f) => f is! PrimaryKeyProperty && f is! ForeignKeyProperty);

  List<Property> get simpleAndPrimaryKeyProperties => this.properties.where((f) => f is! ForeignKeyProperty);

  List<Property> get foreignKeyProperties => this.properties.where((f) => f is ForeignKeyProperty);

  Resource(Type entityType) {
    var classMirror = reflectClass(entityType),
        metadata = classMirror.metadata,
        tableMirror = metadata.firstWhere((im) => im.reflectee is Table, orElse: () => null);

    if (tableMirror == null) {
      throw new ResourceException('Entity should have the Table metadata.');
    }

    var table = (tableMirror.reflectee as Table);

    this.name = MirrorSystem.getName(classMirror.simpleName);
    this.type = entityType;
    this.tableName = table.tableName;
    this.httpMethods = table.allowHttpMethods;
    this.properties = _convertColumnsToProperties(entityType);
  }

  static List<Property> _convertColumnsToProperties(Type entityType) {
    var variableMirrors = reflectClass(entityType).declarations.values
      .where((dm) => dm is VariableMirror)
      .map((dm) => dm as VariableMirror)
      .where((vm) => vm.metadata.any((im) => im.reflectee is Column));

    return variableMirrors.map((vm) {
      var column = vm.metadata.firstWhere((im) => im.reflectee is Column).reflectee as Column,
          name = MirrorSystem.getName(vm.simpleName),
          type = vm.type.reflectedType;

      if (column.isPrimaryKey) {
        return _convertPrimaryKeyColumnToProperty(name, type, column);
      }
      else if (column.isForeignKey) {
        return _convertForeignKeyColumnToProperty(name, type, column, variableMirrors);
      }
      else {
        return _convertColumnToProperty(name, type, column);
      }
    }).toList();
  }

  static Property _convertColumnToProperty(String name, Type type, Column column) {
    if (column.name == null || column.name.isEmpty) {
      throw new ResourceException('Entity \'${type}\' has column \'${name}\' that has an invalid name.');
    }

    return new Property(name, type, column.name);
  }

  static Property _convertPrimaryKeyColumnToProperty(String name, Type type, Column column) {
    if (field.name == null || field.name.isEmpty) {
      throw new ResourceException('Entity \'${type}\' has primary key column \'${name}\' that has an invalid name.');
    }

    return new PrimaryKeyProperty(name, type, column.name);
  }

  static Property _convertForeignKeyColumnToProperty(String name, Type type, Column column, List<VariableMirror> variableMirrors) {
    if (column.idName != null && column.idName.isNotEmpty) {
      if (type is! Type || !reflectType(type).isSubtypeOf(reflectType(Entity))) {
        throw new ResourceException('Many-to-one foreign keys must be of type Entity.');
      }

      if (!variableMirrors.any((vm) => MirrorSystem.getName(vm.simpleName) == column.idName)) {
        throw new ResourceException('Many-to-one foreign keys must point to a Column in the same class.');
      }

      return new ForeignKeyProperty.ManyToOne(name, type, column.idName, column.onUpdate, column.onDelete);
    }
    else if (column.targetName != null && column.targetName.isNotEmpty) {
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

      return new ForeignKeyProperty.OneToMany(name, subType, column.targetName, column.onUpdate, column.onDelete);
    }

    throw new ResourceException('Foreign Key \'$name\' in entity \'$type\' is not structured correctly.');
  }

}
