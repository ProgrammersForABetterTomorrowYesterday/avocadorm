part of property;

/// A representation of an `Entity` foreign key property and information on how it behaves.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// There are currently two types of foreign key [relationships](http://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model)
/// available to the Avocadorm:
///
/// *  **Many-to-one foreign keys**
///
///    For example, an employee "belonging" to a company, written `employee.Company`.
///
/// *  **One-to-many foreign keys**
///
///    For example, a company "possessing" an arbitrary amount of employees, written `company.Employees`.
class ForeignKeyProperty extends Property {

  /// Whether this is a many-to-one foreign key property.
  final bool isManyToOne;

  /// Whether this is a one-to-many foreign key property.
  final bool isOneToMany;

  /// The property that this foreign key targets.
  ///
  /// *  If a many-to-one relationship, the target is a property in the same `Entity` class.
  ///
  ///    For example, an `Employee` class' `Company company` property is a foreign key that targets the `companyId`
  ///    property in the same class, and will match the `Company` instance where the primary key value is equal to
  ///    `companyId`.
  ///
  ///        employee.companyId == 2
  ///        employee.company ==> Company instance whose primary key value is equal to 2
  ///
  /// *  If a one-to-many relationship, the target is a property in the sub-`Entity` class, which will be matched to
  ///    the current `Entity`'s primary key value.
  ///
  ///    For example, a `Company` class' `List<Employee> employees` property is a foreign key that targets the
  ///    `companyId` property of the `Employee` class, and will match all `Employee` instances where the `companyId`
  ///    is equal to the `Company` instance's primary key value.
  ///
  ///        company.companyId == 3
  ///        company.employees ==> List of all Employee instances whose companyId values are equal to 3
  final String targetName;

  /// What to do to this foreign key when saving the `Entity`.
  ///
  /// *  `ReferentialAction.RESTRICT` (default) prevents this foreign key from updating.
  /// *  `ReferentialAction.CASCADE` updates this foreign key and its own updatable foreign keys.
  /// *  `ReferentialAction.SETNULL` (not coded yet).
  final int onUpdateOperation;

  /// What to do to this foreign key when deleting the `Entity`.
  ///
  /// *  `ReferentialAction.RESTRICT` (default) prevents this foreign key from being deleted.
  /// *  `ReferentialAction.CASCADE` deletes this foreign key and its own deletable foreign keys.
  /// *  `ReferentialAction.SETNULL` (not coded yet).
  final int onDeleteOperation;

  /**
   * Creates an instance of a many-to-one foreign key.
   *
   * Creates a many-to-one foreign key [Property] that links an `Entity` property to a database table.
   */
  ForeignKeyProperty.ManyToOne(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isManyToOne = true;

  /**
   * Creates an instance of a one-to-many foreign key.
   *
   * Creates a one-to-many foreign key [Property] that links an `Entity` property to a database table.
   */
  ForeignKeyProperty.OneToMany(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isOneToMany = true;

}
