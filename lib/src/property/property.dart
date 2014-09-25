library property;

part 'primary_key_property.dart';
part 'foreign_key_property.dart';

/// A representation of an [Entity] property and its database column information.
class Property {

  /// The name of the [Entity] property.
  final String name;

  /// The type of the [Entity] property.
  final Type type;

  /// The column name that the [Entity] property is associated with.
  final String columnName;

  /**
   * Creates an instance of a [Property].
   *
   * Creates a normal [Property] that links an [Entity] property to a database column.
   */
  const Property(this.name, this.type, this.columnName);

}
