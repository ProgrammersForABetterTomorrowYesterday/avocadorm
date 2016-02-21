part of property;

/// A representation of an `Entity` foreign key property and information on how it behaves.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// There are currently three types of foreign key [relationships](http://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model)
/// available to the Avocadorm:
///
/// *  **Many-to-one foreign keys**
///
///    For example, an employee "belonging" to a company, written `employee.Company`.
///
/// *  **One-to-many foreign keys**
///
///    For example, a company "possessing" an arbitrary amount of employees, written `company.Employees`.
///
/// *  **Many-to-many foreign keys**
///
///    For example, an employee "possessing" an arbitrary amount of projects, written `employee.Projects`, and a
///    project that can "belong" to multiple employees, written `project.Employees`.
class ForeignKeyProperty extends Property {

  /// Whether to recursively save this foreign key when the entity is saved.
  final bool recursiveSave;

  /// Whether to recursively delete this foreign key when the entity is deleted.
  final bool recursiveDelete;

  const ForeignKeyProperty(String name, Type type, this.recursiveSave, this.recursiveDelete)
    : super(name, type, null);

}
