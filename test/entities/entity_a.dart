part of entities;

@Table('entity_a', allowHttpMethods: HttpMethod.ALL)
class EntityA extends Entity {

  @Column.PrimaryKey('entity_a_id')
  int entityAId;

  @Column('name')
  String name;

  @Column('entity_b_id')
  int entityBId;

  @Column.ManyToOneForeignKey('entityBId', onUpdate: ReferentialAction.CASCADE)
  EntityB entityB;

}
