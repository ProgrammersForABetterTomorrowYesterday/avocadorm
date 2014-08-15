part of entities;

@Table('fk_invalid_o2m_target_entity')
class FkInvalidO2MTargetEntity extends Entity {

  @Column.OneToManyForeignKey('invalidName')
  List<EntityB> entityBs;

}
