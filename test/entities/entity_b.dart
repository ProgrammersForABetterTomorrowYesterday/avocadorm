part of entities;

@Table('entity_b', allowHttpMethods: HttpMethod.GET | HttpMethod.HEAD)
class EntityB extends Entity {

  @Column.PrimaryKey('entity_b_id')
  int entityBId;

  @Column('name')
  String name;

  @Column.OneToManyForeignKey('entityBId')
  List<EntityA> entityAs;

}
