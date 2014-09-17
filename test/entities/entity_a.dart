part of entities;

@Table('entity_a')
class EntityA extends Entity {

  @Column.PrimaryKey('entity_a_id')
  int entityAId;

  @Column('name')
  String name;

  @Column('entity_b_id')
  int entityBId;

  @Column.ManyToOneForeignKey('entityBId', onUpdate: ReferentialAction.CASCADE, onDelete: ReferentialAction.CASCADE)
  EntityB entityB;

  @Column.OneToManyForeignKey('entityAId', onDelete: ReferentialAction.CASCADE)
  List<EntityC> entityCs;

}
