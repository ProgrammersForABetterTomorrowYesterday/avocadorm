part of entities;

@Table('fk_invalid_m2o_id_entity')
class FkInvalidM2OIdEntity extends Entity {

  @Column.ManyToOneForeignKey('entityAId')
  EntityA entityA;

}
