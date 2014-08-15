part of entities;

@Table('entity_b', allowHttpMethods: HttpMethod.ALL)
class EntityB extends Entity {

  @Column.PrimaryKey('entity_b_id')
  int entityBId;

  @Column('name')
  String name;

  @Column('entity_c_id')
  int entityCId;

  @Column.ManyToOneForeignKey('entityCId')
  EntityC entityC;

}
