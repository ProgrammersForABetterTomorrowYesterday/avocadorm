part of entities;

@Table('normal_entity', allowHttpMethods: HttpMethod.POST | HttpMethod.PUT)
class NormalEntity extends Entity {

  @Column('string_property')
  String stringProperty;

  @Column('int_property')
  int intProperty;

}
