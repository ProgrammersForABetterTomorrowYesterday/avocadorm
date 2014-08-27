part of magnetfruit_avocadorm;

abstract class DatabaseHandler {

  Future<Object> create(String table, String pkColumn, List<String> columns, Map data);

  Future<int> count(String table, [List<Filter> filters]);

  Future<List<Map>> read(String table, List<String> columns, [List<Filter> filters, int limit]);

  Future<Object> update(String table, String pkColumn, List<String> columns, Map data);

  Future delete(String table, [List<Filter> filters]);

}
