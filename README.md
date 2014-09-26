#Avocadorm

Avocadorm is an [object-relational mapper](http://en.wikipedia.org/wiki/Object-relational_mapping) (ORM), used to
link database tables to [Dart](http://www.dartlang.org/) objects. Its main focus is to be quick and easy to use.
This is achieved by placing all database-related information in the Entity class.

*  [Homepage](http://www.magnetfruit.com/avocadorm) (not valid yet)
*  [Documentation](http://www.magnetfruit.com/avocadorm/doc) (not valid yet)
*  [GitHub Repository](https://github.com/magnetfruit/avocadorm)
*  [Pub package](https://pub.dartlang.org/packages/magnetfruit_avocadorm)

##Required dependencies##
In order to use the Avocadorm, add the dependency in the *pubspec.yaml*, along with your database handler of choice,
for example:

```
dependencies:
  magnetfruit_avocadorm: ">=0.1.0 <0.2.0"
  magnetfruit_mysql_database_handler: ">=0.1.0 <0.2.0"
```

##Entity class
Entity classes are built to give all the information needed to create queries for the database. This is an example
of a *company.dart* file:

```dart
part of entities;

@Table('company')
class Company extends Entity {

  @Column.PrimaryKey('company_id')
  int companyId;

  @Column('name')
  String name;

  @Column('country_id')
  int countryId;
  
  @Column.ManyToOneForeignKey('countryId')
  Country country;

  @Column.OneToManyForeignKey('companyId', onUpdate: ReferentialAction.CASCADE)
  List<Employee> employees;

}
```

*  **Entity interface** Required. The entity classes must extend from the `Entity` class.
   
*  **Table metadata** Required. Annotate the entity class with a `Table` metadata. The Table metadata's argument is
   the name of the database table.
   
*  **Column metadata** Annotate the entity properties with a `Column` metadata. Properties that do not have this will
   not be mapped to a database table column, and will be skipped. This means you can add constructors, properties, and
   methods to an entity class that have nothing to do with the database. For normal and primary key columns, the
   argument is the database table column. For foreign key properties, the argument is the target property (see
   documentation for more information).

##Entity library
You can import the entity classes one by one to your project, but the easiest way to gather entities together is to
create an entity library. This is a file, for example named *entities.dart*, that contains the entities that the
Avocadorm will map. A very simple entity library could look like this:

```dart
library entities;

import 'package:magnetfruit_entity/entity.dart';

part 'company.dart';
part 'country.dart';
part 'employee.dart';
part 'employee_type.dart';
```

This gives you only one file to import to your project, and they can all be added to the Avocadorm in one line of code.

If you have many entities, it is suggested that they, with the entity library file, be placed in their own folder,
for example */entities*.

##Constructing the Avocadorm
When the entity classes are coded, they can be given to the Avocadorm. Create the Avocadorm by correctly setting a
database handler, then add the entities to it.

```dart
avocadorm = new Avocadorm(databaseHandler)
  ..addEntitiesInLibrary('entities');
```

##Usage
With a valid Avocadorm working, basic CRUD operations (and a few others) can be performed. See the respective
documentation for more information.

*  **Creating** Creates a new entity, regardless of the entity's primary key value.
*  **Counting** Counts how many entities there are, optionally based on a filter.
*  **Reading** Retrieves entities, optionally based on a filter and a list of foreign keys to retrieve.
*  **Updating** Updates an existing entity.
*  **Saving** Creates or updates an entity.
*  **Deleting** Deletes an existing entity.

##Usage example
```
var newEmployee = new Employee()
  ..name = 'Zyrthofar'
  ..email = 'zyrthofar@magnetfruit.com'
  ..companyId = 42
  ..employeeTypeId = 3;

avocadorm.create(newEmployee).then((pkValue) {
  print('New employee's id is ${pkValue}.');
});
```

See the [documentation](http://www.magnetfruit.com/avocadorm/doc), [tutorial](http://www.magnetfruit.com/avocadorm/tutorial),
or the github's [/example](https://github.com/magnetfruit/avocadorm/tree/master/example) project for more information.