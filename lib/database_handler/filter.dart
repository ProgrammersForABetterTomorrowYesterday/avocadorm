part of magnetfruit_avocadorm;

/// A simple AND filter that matches a property name to a value.
class Filter {

  /// The property name.
  String name;

  /// The property value that must be matched.
  Object value;

  /**
   * Creates a [Filter] instance with the name and value combination.
   */
  Filter(this.name, this.value);

}
