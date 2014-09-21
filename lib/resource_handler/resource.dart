part of magnetfruit_avocadorm;

class Resource {
  String name;
  Type type;
  String tableName;
  List<Property> properties;

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
    this.tableName = table.tableName != null && table.tableName.isNotEmpty ? table.tableName : this.name;
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
      else if (column.isManyToOneForeignKey) {
        return _convertManyToOneForeignKeyColumnToProperty(name, type, column, variableMirrors);
      }
      else if (column.isOneToManyForeignKey) {
          return _convertOneToManyForeignKeyColumnToProperty(name, type, column, variableMirrors);
        }
      else {
        return _convertColumnToProperty(name, type, column);
      }
    }).toList();
  }

  static Property _convertColumnToProperty(String name, Type type, Column column) {
    if (column.name == null || column.name.isEmpty) {
      column.name = name;
    }

    return new Property(name, type, column.name);
  }

  static Property _convertPrimaryKeyColumnToProperty(String name, Type type, Column column) {
    if (column.name == null || column.name.isEmpty) {
      column.name = name;
    }

    var r = reflectType(type);
    if (!r.isSubtypeOf(reflectType(num)) && !r.isSubtypeOf(reflectType(String))) {
      throw new ResourceException('Primary keys should be a value type.');
    }

    return new PrimaryKeyProperty(name, type, column.name);
  }

  static Property _convertManyToOneForeignKeyColumnToProperty(String name, Type type, Column column, List<VariableMirror> variableMirrors) {
    if (type is! Type || !reflectType(type).isSubtypeOf(reflectType(Entity))) {
      throw new ResourceException('Many-to-one foreign keys must be of type Entity.');
    }

    if (!variableMirrors.any((vm) => MirrorSystem.getName(vm.simpleName) == column.targetName)) {
      throw new ResourceException('Many-to-one foreign keys must point to a Column in the same class.');
    }

    if (column.targetName == null || column.targetName.isEmpty) {
      column.targetName = '${name}Id';
    }

    return new ForeignKeyProperty.ManyToOne(name, type, column.targetName, column.onUpdate, column.onDelete);
  }

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

    if (column.targetName == null || column.targetName.isEmpty) {
      column.targetName = '${MirrorSystem.getName(reflectType(subType).simpleName)}Id';
    }

    return new ForeignKeyProperty.OneToMany(name, subType, column.targetName, column.onUpdate, column.onDelete);
  }

}
