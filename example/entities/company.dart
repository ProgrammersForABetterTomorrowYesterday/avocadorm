part of entities;

@Table('company', allowHttpMethods: HttpMethod.ALL)
class Company extends Entity {

  @Column.PrimaryKey('company_id')
  int companyId;

  @Column('name')
  String name;

  @Column.OneToManyForeignKey('companyId', onUpdate: ReferentialAction.CASCADE)
  List<Employee> employees;

}
