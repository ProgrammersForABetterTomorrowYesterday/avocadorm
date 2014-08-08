part of magnetfruit_avocadorm;

abstract class DatabaseHandler {

  Future<List<Map>> retrieveAll(String table, List<String> columns);

  Future<Map> retrieveById(String table, List<String> columns, String pkColumn, Object pkValue);

  Future<Object> save(String table, List<String> columns, String pkColumn, Map data);

  Future delete(String table, String pkColumn, Object pkValue);

}