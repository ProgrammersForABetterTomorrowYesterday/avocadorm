part of invalid_entities;

@Table('fk_invalid_m2m_list_entity')
class FkInvalidM2MListEntity extends Entity {

  @Column.ManyToManyForeignKey('junction_table', 'first_entity_id', 'second_entity_id')
  NormalEntity normalEntities;

}
