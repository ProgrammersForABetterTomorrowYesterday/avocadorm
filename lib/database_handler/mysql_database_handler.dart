import 'dart:async';
import 'dart:mirrors';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:sqljocky/sqljocky.dart';

class MySqlDatabaseHandler extends DatabaseHandler {
  ConnectionPool pool;

  MySqlDatabaseHandler(String host, int port, String database, String user, String password) {
    this.pool = new ConnectionPool(host: host, port: port, db: database, user: user, password: password);
  }

  Future<List<Map>> retrieveAll(String table, List<String> columns, [List<PropertyFilter> propertyFilters]) {
    var cols = columns.map((c) => '`${c}`');

    var script = 'SELECT ${cols.join(', ')} FROM `${table}`;';

    if (propertyFilters != null) {
      var filters = propertyFilters.map((f) => '`${f.property.columnName}` = ${this._objToString(f.value)}');

      script += '\nWHERE ${filters.join(' AND ')}';
    }

    return this.pool.query(script).then((results) {
      return results.toList().then((rows) {
        return rows.map((r) => _constructMapFromDatabase(r, results.fields)).toList();
      });
    });
  }

  Future<Map> retrieveById(String table, List<String> columns, String pkColumn, Object pkValue) {
    var cols = columns.map((c) => '`${c}`');
    var value = this._objToString(pkValue);

    var script = 'SELECT ${cols.join(', ')} FROM `${table}`';
    script += '\nWHERE `${pkColumn}` = ${value};';

    return this.pool.query(script).then((results) {
      return results.toList().then((rows) {
        return rows;
      });
    });
  }

  Future<Object> save(String table, List<String> columns, String pkColumn, Map data) {
    var cols = columns.map((c) => '`${c}`').toList().add('`${pkColumn}`');
    var values = data.values.map((v) =>  this._objToString(v));

    var script = 'INSERT INTO `${table}` (${cols.join(', ')})';
    script += '\nVALUES (${values.join(', ')})';

    if (data[pkColumn] != null) {
      script += '\nON DUPLICATE KEY UPDATE';
      script += '\n${cols.map((c) => '`${c}` = VALUES(`${c}`)').join(', ')}';
    }

    script += ';';

    return this.pool.query(script).then((result) {
      return new Future.value(result.insertId);
    });
  }

  Future delete(String table, String pkColumn, Object pkValue) {
    var value = this._objToString(pkValue);

    var script = 'DELETE FROM `${table}`';
    script += '\nWHERE `${pkColumn}` = ${value}';

    return this.pool.query(script).then((result) {
      return new Future.value(null);
    });
  }

  Map _constructMapFromDatabase(Row input, List<Field> fields) {
    var output = new Map<String, Object>();

    InstanceMirror instanceMirror = reflect(input);
    fields.forEach((field) {
      output[field.name] = instanceMirror.getField(new Symbol(field.name)).reflectee;
    });

    return output;
  }

  String _objToString(Object value) {
    if (value is String) {
      return '\'${value}\'';
    }

    if (value == null) {
      return 'NULL';
    }

    return value.toString();
  }
}
