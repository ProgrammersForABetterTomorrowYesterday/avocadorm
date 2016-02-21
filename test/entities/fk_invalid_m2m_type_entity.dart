part of invalid_entities;

@Table('fk_invalid_m2m_type_entity')
class FkInvalidM2MTypeEntity extends Entity {

  @Column.ManyToManyForeignKey('junction_table', 'first_entity_id', 'second_entity_id')
  List<String> normalEntities;

}
