part of magnetfruit_avocadorm;

/// Implementation definition of a [DatabaseHandler].
abstract class DatabaseHandler {

  /**
   * Creates a new table row in the database.
   *
   * Creates a new table row with the specified [data]. The [columns] list has the normal columns only, and
   * excludes the primary key column. Returns a [Future] containing the primary key value of the new table row. The
   * primary key is expected to be null or non-existant in the table.
   */
  Future<Object> create(String table, String pkColumn, List<String> columns, Map data);

  /**
   * Counts how many table rows are in the database.
   *
   * If [filters] list is null or empty, counts the total amount of table rows in the specified table. Otherwise,
   * counts how many table rows match the specified list of filter. Returns a [Future] containing the count.
   */
  Future<int> count(String table, [List<Filter> filters]);

  /**
   * Reads table rows in the database.
   *
   * Reads the specified [columns] from the specified [table], in respect of optional [filters] list and [limit].
   * Returns a [Future] containing a list of [Map] with the required values. Reading by primary key value should
   * use this method with [limit] = 1, and take the first item.
   */
  Future<List<Map>> read(String table, List<String> columns, [List<Filter> filters, int limit]);

  /**
   * Updates a table row in the database.
   *
   * Updates a table row with the specified [data]. The [columns] list has the normal columns only, and
   * excludes the primary key column. Returns a [Future] containing the primary key value of the new table row. The
   * primary key is expected to be existant in the table.
   */
  Future<Object> update(String table, String pkColumn, List<String> columns, Map data);

  /**
   * Deletes a table row from the database.
   *
   * Deletes the table rows matching the [filters] list. If [filters] is null or empty, this will delete all table
   * rows from the specified [table].
   */
  Future delete(String table, [List<Filter> filters]);

}
