part of entities;

@Table('employee')
class Employee extends Entity {

  @Column.PrimaryKey('employee_id')
  int employeeId;

  @Column('name')
  String name;

  @Column('address')
  String address;

  @Column('company_id')
  int companyId;

  @Column('email')
  String email;

  @Column.ManyToOneForeignKey('companyId')
  Company company;

  @Column('employee_type_id')
  int employeeTypeId;

  @Column.ManyToOneForeignKey('employeeTypeId')
  EmployeeType employeeType;

}
