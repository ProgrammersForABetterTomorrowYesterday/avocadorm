part of avocadorm_test;

class MockDatabaseHandler extends Mock implements DatabaseHandler {

  Future<Object> create(String table, String pkColumn, List<String> columns, Map data) {
    var entities = _entityRepository[table];

    data[pkColumn] = entities.map((e) => e[pkColumn]).reduce(max) + 1;

    entities.add(data);

    return new Future.value(data[pkColumn]);
  }

  Future<int> count(String table, [List<Filter> filters]) {
    var entities = _entityRepository[table];

    if (filters != null) {
      entities = entities.where((e) => filters.every((f) => e[f.column] == f.value));
    }

    return new Future.value(entities.length);
  }

  Future<List<Map>> read(String table, List<String> columns, [List<Filter> filters, int limit]) {
    var entities = _entityRepository[table];

    if (filters != null) {
      entities = entities.where((e) => filters.every((f) => e[f.column] == f.value));
    }

    if (limit != null) {
      entities = entities.take(limit);
    }

    return new Future.value(entities);
  }

  Future<Object> update(String table, String pkColumn, List<String> columns, Map data) {
    var entities = _entityRepository[table];

    if (!data.containsKey(pkColumn) || data[pkColumn] == null) {
      return this.create(table, pkColumn, column, data);
    }

    entities
      ..removeWhere((e) => e[pkColumn] == data[pkColumn])
      ..add(data);

    return new Future.value(data[pkColumn]);
  }

  Future delete(String table, [List<Filter> filters]) {
    var entities = _entityRepository[table];

    if (filters != null) {
      entities.removeWhere((e) => filters.every((f) => e[f.column] == f.value));
    }

    return new Future.value(null);
  }

}

Map<Type, List<Map>> _entityRepository = new Map<Type, List<Map>>();

void setEntities() {
  _entityRepository['entity_a'] = [
      { 'entity_a_id': 1, 'name': 'First EntityA', 'entity_b_id': 1 },
      { 'entity_a_id': 2, 'name': 'Second EntityA', 'entity_b_id': 2 },
      { 'entity_a_id': 3, 'name': 'Third EntityA', 'entity_b_id': null },
      { 'entity_a_id': 4, 'name': 'Fourth EntityA', 'entity_b_id': 3 },
      { 'entity_a_id': 5, 'name': 'Fifth EntityA', 'entity_b_id': 2 }
  ];

  _entityRepository['entity_b'] = [
      { 'entity_b_id': 1, 'name': 'First EntityB' },
      { 'entity_b_id': 2, 'name': 'Second EntityB' },
      { 'entity_b_id': 3, 'name': 'Third EntityB' },
      { 'entity_b_id': 4, 'name': 'Fourth EntityB' },
      { 'entity_b_id': 5, 'name': 'Fifth EntityB' },
      { 'entity_b_id': 6, 'name': 'Sixth EntityB' },
  ];
}
