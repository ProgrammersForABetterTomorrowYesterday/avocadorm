part of entities;

@Table('employee_type', allowHttpMethods: HttpMethod.HEAD | HttpMethod.GET)
class EmployeeType extends Entity {

  @Column.PrimaryKey('employee_type_id')
  int employeeTypeId;

  @Column('name')
  String name;

}
