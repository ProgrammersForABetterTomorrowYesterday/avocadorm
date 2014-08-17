import 'dart:convert';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:magnetfruit_avocadorm/database_handler/mysql_database_handler.dart';
import 'entities/entities.dart';

void main() {
  // avocadorm_guest has SELECT privileges.
  //var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_guest', 'pwd');

  // avocadorm_admin has SELECT, INSERT, UPDATE, and DELETE privileges.
  var databaseHandler = new MySqlDatabaseHandler('localhost', 3306, 'avocadorm_example', 'avocadorm_admin', 'password');

  var avocadorm = new Avocadorm(databaseHandler)
    ..addEntitiesInLibrary('entities');

  avocadorm.readById(Employee, 2).then((employee) {
    print(JSON.encode(employee));

    employee.name = 'Christina Johnson';

    avocadorm.update(employee).then((id) {

      avocadorm.readById(Employee, 2).then((employee) {
        print(JSON.encode(employee));
      });

    });
  });
}
   