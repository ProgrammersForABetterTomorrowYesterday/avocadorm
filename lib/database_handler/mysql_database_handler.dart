import 'dart:async';
import 'dart:mirrors';
import 'package:magnetfruit_avocadorm/avocadorm.dart';
import 'package:sqljocky/sqljocky.dart';

class MySqlDatabaseHandler extends DatabaseHandler {
  ConnectionPool pool;

  MySqlDatabaseHandler(String host, int port, String database, String user, String password) {
    this.pool = new ConnectionPool(host: host, port: port, db: database, user: user, password: password);
  }

  Future<Object> create(String table, String pkColumn, List<String> columns, Map data) {
    columns.insert(0, pkColumn);

    var cols = columns.map((c) => '`${c}`'),
        values = columns.map((c) => _objToString(data[c]));

    var script = 'INSERT INTO `${table}` (${cols.join(', ')})';
    script += '\nVALUES (${values.join(', ')});';

    return this.pool.query(script).then((result) {
      return new Future.value(result.insertId);
    });
  }

  Future<int> count(String table, [List<Filter> filters]) {
    var script = 'SELECT COUNT(*) FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

    script += ';';

    return this.pool.query(script).then((results) {
      return results.first.then((row) {
        return row.first;
      });
    });
  }

  Future<List<Map>> read(String table, List<String> columns, [List<Filter> filters, int limit]) {
    var cols = columns.map((c) => '`${c}`');

    var script = 'SELECT ${cols.join(', ')} FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

    if (limit != null) {
      script += '\nLIMIT ${limit}';
    }

    script += ';';

    return this.pool.query(script).then((results) {
      return results.toList().then((rows) {
        return rows.map((r) => _constructMapFromDatabase(r, results.fields)).toList();
      });
    });
  }

  Future<Object> update(String table, String pkColumn, List<String> columns, Map data) {
    columns.insert(0, pkColumn);

    var cols = columns.map((c) => '`${c}`'),
        values = columns.map((c) =>  _objToString(data[c]));

    var script = 'INSERT INTO `${table}` (${cols.join(', ')})';
    script += '\nVALUES (${values.join(', ')})';
    script += '\nON DUPLICATE KEY UPDATE';
    script += '\n${cols.map((c) => '${c} = VALUES(${c})').join(', ')};';

    return this.pool.query(script).then((result) {
      return new Future.value(result.insertId);
    });
  }

  Future delete(String table, [List<Filter> filters]) {
    var script = 'DELETE FROM `${table}`';

    if (filters != null && filters.length > 0) {
      script += '\nWHERE ${_constructFilter(filters)}';
    }

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

  static String _objToString(Object value) {
    if (value is String) {
      return '\'${value}\'';
    }

    if (value == null) {
      return 'NULL';
    }

    return value.toString();
  }

  static String _constructFilter(List<Filter> filters) {
    return filters.map((f) => '`${f.column}` = ${_objToString(f.value)}').join(' AND ');
  }
}
