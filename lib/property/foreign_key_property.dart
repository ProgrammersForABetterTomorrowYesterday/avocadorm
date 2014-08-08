part of magnetfruit_avocadorm;

class ForeignKeyProperty extends Property {
  final bool isOneToMany;
  final bool isManyToOne;

  final String targetName;
  final int onUpdateOperation;
  final int onDeleteOperation;

  ApiForeignKeyProperty.ManyToOne(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isManyToOne = true;

  ApiForeignKeyProperty.OneToMany(String name, Type type, this.targetName, this.onUpdateOperation, this.onDeleteOperation)
    : super(name, type, null), isOneToMany = true;
}
