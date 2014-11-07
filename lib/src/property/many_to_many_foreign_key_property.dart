part of property;

/// A representation of an `Entity` foreign key property and information on how it behaves.
///
/// This is an internal implementation, and as such, no garantee can be given concerning breaking changes.
/// Constructors, properties, and methods should not be available to the user.
///
/// Many-to-many foreign keys are the properties to which correspond many entities, and the reverse is also true.
/// For example, a teacher could have a `students` many-to-many property, which is accessed as `teacher.students`,
/// and the student have a `teachers` many-to-many property, which is accessed as `student.teachers`.
class ManyToManyForeignKeyProperty extends ForeignKeyProperty {

  /// The name of the database junction table.
  ///
  /// Used by many-to-many foreign key properties to find the other entity that is joined to the current one.
  ///
  ///     teacher.teacherId == 4
  ///     teacher.students ==> all Student instances whose id match the student id in the given junction table.
  final String junctionTableName;

  /// The column name of the current entity in the junction table.
  final String targetColumnName;

  /// The column name of the other entity in the junction table.
  final String otherColumnName;

  const ManyToManyForeignKeyProperty(String name, Type type, this.junctionTableName, this.targetColumnName, this.otherColumnName, bool recursiveSave, bool recursiveDelete)
    : super(name, type, recursiveSave, recursiveDelete);

}
