part of entities;

@Table('company')
class Company extends Entity {

  @Column.PrimaryKey('company_id')
  int companyId;

  @Column('name')
  String name;

  @Column.OneToManyForeignKey('companyId', recursiveSave: true)
  List<Employee> employees;

}
