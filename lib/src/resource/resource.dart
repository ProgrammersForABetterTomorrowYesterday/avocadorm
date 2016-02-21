part of resource;

class Resource {

  /// The name of the `Entity`.
  String name;

  /// The type of the `Entity`.
  Type type;

  /// The name of the table in the database.
  String tableName;

  /// The list of properties contained in the `Entity`.
  List<Property> properties;

  /// The primary key property that the `Entity` will be identified with.
  ///
  /// There can currently be only one primary key property on an `Entity`. While additional primary keys can be
  /// set, only the first one will be used.
  Property get primaryKeyProperty => this.properties.firstWhere((f) => f is PrimaryKeyProperty, orElse: null);

  /// The normal properties contained in the [Entity].
  List<Property> get simpleProperties => this.properties.where((f) => f is! PrimaryKeyProperty && f is! ForeignKeyProperty).toList();

  /// The primary key property and normal properties contained in the [Entity].
  List<Property> get simpleAndPrimaryKeyProperties => this.properties.where((f) => f is! ForeignKeyProperty).toList();

  /// The foreign key properties contained in the [Entity].
  List<Property> get foreignKeyProperties => this.properties.where((f) => f is ForeignKeyProperty).toList();

}
