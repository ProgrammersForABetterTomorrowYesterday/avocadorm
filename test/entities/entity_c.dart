part of entities;

@Table('entity_c')
class EntityC extends Entity {

  @Column.PrimaryKey('entity_c_id')
  int entityCId;

  @Column('name')
  String name;

  @Column('entity_a_id')
  int entityAId;

  @Column.ManyToOneForeignKey('entityAId')
  EntityA entityA;

}
