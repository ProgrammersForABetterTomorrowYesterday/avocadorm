part of entities;

@Table('fk_invalid_m2o_type_entity')
class FkInvalidM2OTypeEntity extends Entity {

  @Column('entity_a_id')
  int entityAId;

  @Column.ManyToOneForeignKey('entityAId')
  String entityA;

}
