part of property;

/// A representation of an `Entity` foreign key property and information on how it behaves.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// One-to-many foreign keys are the properties to which correspond many entities. For example, a teacher
/// could have a `courses` one-to-many property, which is accessed as `teacher.courses`.
class OneToManyForeignKeyProperty extends ForeignKeyProperty {

  /// The property that this foreign key targets.
  ///
  /// If a one-to-many relationship, the target is a property in the sub-`Entity` class, which will be matched to
  /// the current `Entity`'s primary key value.
  ///
  /// For example, a `Teacher` class' `List<Course> courses` property is a foreign key that targets the
  /// `teacherId` property of the `Course` class, and will match all `Course` instances where the `teacherId`
  /// is equal to the `Teacher` instance's primary key value.
  ///
  ///     teacher.teacherId == 3
  ///     teacher.courses ==> List of all Course instances whose teacherId values are equal to 3
  const OneToManyForeignKeyProperty(String name, Type type, String targetName, bool recursiveSave, bool recursiveDelete)
    : super(name, type, recursiveSave, recursiveDelete, column: targetName);

}
