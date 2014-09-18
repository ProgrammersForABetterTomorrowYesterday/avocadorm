part of invalid_entities;

@Table('fk_invalid_m2o_type_entity')
class FkInvalidM2OTypeEntity extends Entity {

  @Column('entity_id')
  int entityId;

  @Column.ManyToOneForeignKey('entityId')
  String entity;

}
