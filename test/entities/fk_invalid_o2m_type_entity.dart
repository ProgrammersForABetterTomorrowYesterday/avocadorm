part of entities;

@Table('fk_invalid_o2m_type_entity')
class FkInvalidO2MTypeEntity extends Entity {

  @Column.OneToManyForeignKey('name')
  List<String> entityBs;

}
