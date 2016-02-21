part of property;

/// A representation of an `Entity` many-to-one foreign key property and information on how it behaves.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// Many-to-one foreign keys are the properties that correspond to another entity. For example, a teacher
/// could have a `school` many-to-one foreign key property, which is accessed as `teacher.school`.
class ManyToOneForeignKeyProperty extends ForeignKeyProperty {

  /// The property that this foreign key targets.
  ///
  /// For example, an `Teacher` class' `School school` property is a foreign key that targets the `schoolId`
  /// property in the same class, and will match the `School` instance where the primary key value is equal to
  /// `schoolId`.
  ///
  ///     teacher.schoolId == 2
  ///     teacher.school ==> School instance whose primary key value is equal to 2
  final String targetName;

  const ManyToOneForeignKeyProperty(String name, Type type, this.targetName, bool recursiveSave, bool recursiveDelete)
    : super(name, type, recursiveSave, recursiveDelete);

}
