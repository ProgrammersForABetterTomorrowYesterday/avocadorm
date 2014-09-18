part of invalid_entities;

@Table('normal_entity')
class NormalEntity extends Entity {

  @Column('string_property')
  String stringProperty;

  @Column('int_property')
  int intProperty;

}
