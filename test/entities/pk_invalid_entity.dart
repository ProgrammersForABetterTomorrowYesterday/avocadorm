part of invalid_entities;

@Table('pk_invalid_entity')
class PkInvalidEntity extends Entity {

  @Column.PrimaryKey('pk')
  Map pk;

}
