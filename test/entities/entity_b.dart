part of entities;

@Table('entity_b')
class EntityB extends Entity {

  @Column.PrimaryKey('entity_b_id')
  int entityBId;

  @Column('name')
  String name;

  @Column.OneToManyForeignKey('entityBId', onUpdate: ReferentialAction.CASCADE)
  List<EntityA> entityAs;

  @Column.ManyToManyForeignKey('entity_b_entity_c', 'entity_b_id', 'entity_c_id', onUpdate: ReferentialAction.CASCADE, onDelete: ReferentialAction.CASCADE)
  List<EntityC> entityCs;
}
