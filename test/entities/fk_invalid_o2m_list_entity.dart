part of entities;

@Table('fk_invalid_o2m_list_entity')
class FkInvalidO2MListEntity extends Entity {

  @Column.OneToManyForeignKey('name')
  EntityB entityBs;

}
