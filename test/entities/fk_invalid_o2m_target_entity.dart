part of invalid_entities;

@Table('fk_invalid_o2m_target_entity')
class FkInvalidO2MTargetEntity extends Entity {

  @Column.OneToManyForeignKey('invalidName')
  List<NormalEntity> normalEntities;

}
