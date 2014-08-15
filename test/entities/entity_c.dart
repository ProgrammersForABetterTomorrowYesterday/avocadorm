part of entities;

@Table('entity_c', allowHttpMethods: HttpMethod.GET | HttpMethod.HEAD)
class EntityC extends Entity {

  @Column.PrimaryKey('entity_c_id')
  int entityCId;

  @Column('name')
  String name;

}
