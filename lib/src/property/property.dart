library property;

part 'primary_key_property.dart';
part 'foreign_key_property.dart';

/// A representation of an `Entity` property and its database column information.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// A property is a link between an `Entity` property, and a database table column. It is the most basic property,
/// and [PrimaryKeyProperty] and [ForeignKeyProperty] extends from it.
class Property {

  /// The name of the `Entity` property.
  final String name;

  /// The type of the `Entity` property.
  final Type type;

  /// The column name that the `Entity` property is associated with in the database.
  final String columnName;

  /**
   * Creates an instance of a property.
   *
   * Creates a normal [Property] that links an `Entity` property to a database column.
   */
  const Property(this.name, this.type, this.columnName);

}
