#Avocadorm

Avocadorm is an [object-relational mapper](http://en.wikipedia.org/wiki/Object-relational_mapping) (ORM), used to
link database tables to [Dart](http://www.dartlang.org/) objects. Its main focus is to be quick and easy to use.
This is achieved by coding all database-related information in the entity classes.

*  [Homepage](http://www.magnetfruit.com/avocadorm)
*  [GitHub Repository](https://github.com/magnetfruit/avocadorm)
*  [Pub package](https://pub.dartlang.org/packages/magnetfruit_avocadorm)

##Creating the avocadorm
In order to create the avocadorm, you need to tell it about your database by means of a [database handler](http://www.magnetfruit.com/databasehandler/),
then feed it with your [entities](http://www.magnetfruit.com/entity/).

```dart
avocadorm = new Avocadorm(databaseHandler)
  ..addEntitiesInLibrary('entities');
```

##Usage
With a valid Avocadorm in your hands, CRUD operations (and a few others) can be performed. See the
[documentation](http://www.magnetfruit.com/avocadorm/documentation.html) for more information about these methods.

With the avocadorm, you can

-  Create a new entity
-  Count entities
-  Retrieve entities
-  Update an entity
-  Delete an entity

##Usage example
```dart
var newEmployee = new Employee()
  ..name = 'Zyrthofar'
  ..companyId = 42;

avocadorm.create(newEmployee).then((pkValue) {
  print('New employee\'s id is ${pkValue}.');
});
```

See the [examples](http://www.magnetfruit.com/avocadorm/examples) page or the ready-to-use GitHub's
[/example](https://github.com/magnetfruit/avocadorm/tree/master/example) project for more examples.

##Dependencies
In order to use the Avocadorm, add the dependency in your *pubspec.yaml*, along with your database handler of choice.
For example:

```
dependencies:
  magnetfruit_avocadorm: ">=0.1.0 <0.2.0"
  magnetfruit_mysql_database_handler: ">=0.1.0 <0.2.0"
```
