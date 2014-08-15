part of entities;

@Table('pk_int_entity')
class PkIntEntity extends Entity {

  @Column.PrimaryKey('pk_int_property')
  int pkIntProperty;

}
