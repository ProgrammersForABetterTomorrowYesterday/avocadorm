part of entities;

@Table('fk_entity')
class FkEntity extends Entity {

  @Column('entity_a_id')
  int entityAId;

  @Column.ManyToOneForeignKey('entityAId')
  EntityA entityA;

  @Column.OneToManyForeignKey('entityCId')
  List<EntityB> entityBs;

}
