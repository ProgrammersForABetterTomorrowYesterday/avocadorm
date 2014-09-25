part of property;

/// A representation of an [Entity] foreign key property and information on how it behaves.
class ForeignKeyProperty extends Property {

  /// Whether this is a many-to-one foreign key property.
  final bool isManyToOne;

  /// Whether this is a one-to-many foreign key property.
  final bool isOneToMany;

  /// The property that this foreign key targets.
  /// If a many-to-one, the target is a property in the same [Entity] class.
  /// If a one-to-many, the target is a property in the sub-[Entity] class, which will be matched to the current
  /// [Entity]'s primary key value.
  final String targetName;

  /// What to do to this foreign key when saving the [Entity].
  final int onUpdateOperation;

  /// What to do to this foreign key when deleting the [Entity].
  final int onDeleteOperation;

  /**
   * Creates an instance of a many-to-one [ForeignKeyProperty].
   *
   * Creates a many-to-one foreign key [Property] that links an [Entity] property to a database table.
   */
  ForeignKeyProperty.ManyToOne(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isManyToOne = true;

  /**
   * Creates an instance of a one-to-many [ForeignKeyProperty].
   *
   * Creates a one-to-many foreign key [Property] that links an [Entity] property to a database table.
   */
  ForeignKeyProperty.OneToMany(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isOneToMany = true;

}
