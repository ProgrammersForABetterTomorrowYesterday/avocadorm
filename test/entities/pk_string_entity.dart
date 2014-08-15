part of entities;

@Table('pk_string_entity')
class PkStringEntity extends Entity {

  @Column.PrimaryKey('pk_string_property')
  String pkStringProperty;

}
