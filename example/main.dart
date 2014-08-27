import 'dart:async';
import 'dart:convert';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:magnetfruit_avocadorm/database_handler/mysql_database_handler.dart';
import 'entities/entities.dart';

var avocadorm;

void main() {
  // avocadorm_guest has SELECT privileges.
  //var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_guest', 'pwd');

  // avocadorm_admin has SELECT, INSERT, UPDATE, and DELETE privileges.
  var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_admin', 'password');

  avocadorm = new Avocadorm(databaseHandler)
    ..addEntitiesInLibrary('entities');

  getEmployee(2)
    .then(toggleName)
    .then(updateEmployee)
    .then(getEmployee);

  avocadorm.readById(Company, 3, foreignKeys: ['employees']).then((company) {

    print(JSON.encode(company));

  });

}

Future getEmployee(Object id) {
  return avocadorm.readById(Employee, id)
    .then((e) {
      print(JSON.encode(e));
      return e;
    });
}

Future toggleName(Employee employee) {
  if (employee.name == 'Christina Johnson') {
    employee.name = 'Rosetta Peters';
  }
  else {
    employee.name = 'Christina Johnson';
  }

  return new Future.value(employee);
}

Future updateEmployee(Employee employee) {
  return avocadorm.update(employee);
}
