part of property;

/// A representation of an `Entity` primary key property and its database column information.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// A primary key is a [unique key](http://en.wikipedia.org/wiki/Unique_key) that identifies an entity from all
/// other entities. No two entities are allowed to have the same primary key value. There can only be one primary
/// key per entity.
class PrimaryKeyProperty extends Property {

  /**
   * Creates an instance of a primary key.
   *
   * Creates a primary key [Property] that links an `Entity` property to a database primary key column.
   */
  const PrimaryKeyProperty(String name, Type type, String columnName) : super(name, type, columnName);

}
