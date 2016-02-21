part of entities;

@Table('entity_a')
class EntityA extends Entity {

  @Column.PrimaryKey('entity_a_id')
  int entityAId;

  @Column('name')
  String name;

  @Column('entity_b_id')
  int entityBId;

  @Column.ManyToOneForeignKey('entityBId', recursiveSave: true, recursiveDelete: true)
  EntityB entityB;

  @Column.OneToManyForeignKey('entityAId', recursiveDelete: true)
  List<EntityC> entityCs;

}
