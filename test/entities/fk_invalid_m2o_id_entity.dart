part of invalid_entities;

@Table('fk_invalid_m2o_id_entity')
class FkInvalidM2OIdEntity extends Entity {

  @Column.ManyToOneForeignKey('normalEntityId')
  NormalEntity normalEntity;

}
