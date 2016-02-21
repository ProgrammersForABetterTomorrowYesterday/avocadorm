import 'dart:async';
import 'dart:convert';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:magnetfruit_mysql_database_handler/mysql_database_handler.dart';
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

void main() {

  //var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_guest', 'pwd');
  var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_admin', 'password');


  // Creates an avocadorm instance to the specified database,
  // with all [Entity]s contained in the 'entities' library.
  var avocadorm = new Avocadorm()
    ..setDatabaseHandler(databaseHandler)
    ..addEntitiesInLibrary('entities');


  // Counts how many Employee rows there are in the database.
  avocadorm.count(Employee)
    .then((count) => print('There are $count employees.'));

  // Retrieves the company with primary key 3, along with its employees one-to-many foreign key.
  avocadorm.readById(Company, 3, foreignKeys: ['employees'])
    .then((company) {

      print('Company: ${JSON.encode(company)}');

    });


  // For creating, updating, saving, or deleting an entity, you can use the entity directly. For example, the
  // following two create() are identical.
  var newEmployee = new Employee()..name='John Smith';

  newEmployee.create()
    .then((pk) => print('New employee id with entity.create(): $pk'));

  avocadorm.create(newEmployee)
    .then((pk) => print('New employee id with avocadorm.create(entity): $pk'));


  // You can chain multiple operations to the Avocadorm. The following reads an Employee by its primary key, prints
  // the JSON object, toggles the name, updates it in the database, reads it again, and finally prints the JSON
  // object again to compate the before / after. Notice that all called methods deal in [Future]s. This is required
  // for chaining methods async.
  avocadorm.readById(Employee, 2)
    .then((e) {
      print('Employee before: ${JSON.encode(e)}');
      return e;
    })
    .then((e) {
      e.name = e.name == 'Christina Johnson'
        ? 'Rosetta Peters'
        : 'Christina Johnson';

      return new Future.value(e);
    })
    .then((e) => avocadorm.update(e))
    .then((id) => avocadorm.readById(Employee, id))
    .then((e) => print('Employee after: ${JSON.encode(e)}'));

}
