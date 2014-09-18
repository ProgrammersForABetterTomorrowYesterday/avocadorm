part of invalid_entities;

@Table('fk_invalid_o2m_list_entity')
class FkInvalidO2MListEntity extends Entity {

  @Column.OneToManyForeignKey('normalEntityId')
  NormalEntity normalEntities;

}
