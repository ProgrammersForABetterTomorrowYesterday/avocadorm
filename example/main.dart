import 'dart:async';
import 'dart:convert';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:magnetfruit_avocadorm/database_handler/mysql_database_handler.dart';
import 'entities/entities.dart';

// This example can be used after executing the mysql_script.sql script.
// The script will create:
// - the avocadorm_example database;
// - an avocadorm_guest user with SELECT privileges;
// - an avocadorm_admin user with SELECT, INSERT, UPDATE, and DELETE privileges;
// - three tables (employee, company, employee_type) with some data.
//
// Running this example will print some JSON to the console.
// The JSONs may not be printed in the order expected by the code, as the database queries are made async. They
// are printed as they are finished.

var avocadorm;

void main() {

  //var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_guest', 'pwd');
  var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_admin', 'password');

  // Creates an avocadorm instance to the specified database,
  // with all [Entity]s contained in the 'entities' library.
  avocadorm = new Avocadorm(databaseHandler)
    ..addEntitiesInLibrary('entities');

  // Retrieves the employee with primary key value 2, changes the name, updates the value, then re-retrieves
  // the same employee to compare the values. Notice that all called methods deal in [Future]s. This is required
  // for chaining methods async.
  getEmployee(2)
    .then(toggleName)
    .then(updateEmployee)
    .then(getEmployee);

  // Retrieves the company with primary key 3, along with its employees one-to-many foreign key.
  avocadorm.readById(Company, 3, foreignKeys: ['employees']).then((company) {

    print(JSON.encode(company));

  });

}

/// Retrieves an employee by its primary key value, then prints its JSON.
Future getEmployee(Object id) {
  return avocadorm.readById(Employee, id)
    .then((e) {
      print(JSON.encode(e));
      return e;
    });
}

/// Changes the name of the specified employee.
Future toggleName(Employee employee) {
  if (employee.name == 'Christina Johnson') {
    employee.name = 'Rosetta Peters';
  }
  else {
    employee.name = 'Christina Johnson';
  }

  return new Future.value(employee);
}

/// Updates the specified employee.
Future updateEmployee(Employee employee) {
  return avocadorm.update(employee);
}
