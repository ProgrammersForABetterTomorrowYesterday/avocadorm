part of magnetfruit_avocadorm;

/// A representation of an [Entity] primary key property and its database column information.
class PrimaryKeyProperty extends Property {

  /**
   * Creates an instance of a [PrimaryKeyProperty].
   *
   * Creates a primary key [Property] that links an [Entity] property to a database primary key column.
   */
  PrimaryKeyProperty(String name, Type type, String columnName) : super(name, type, columnName);

}
