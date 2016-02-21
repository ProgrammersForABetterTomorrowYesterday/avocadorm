part of entities;

@Table('entity_c')
class EntityC extends Entity {

  @Column.PrimaryKey('entity_c_id')
  String entityCId;

  @Column('name')
  String name;

  @Column('entity_a_id')
  int entityAId;

  @Column.ManyToOneForeignKey('entityAId')
  EntityA entityA;

  @Column.ManyToManyForeignKey('entity_b_entity_c', 'entity_c_id', 'entity_b_id')
  List<EntityB> entityBs;

}
