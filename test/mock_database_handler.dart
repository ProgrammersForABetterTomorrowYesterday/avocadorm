part of avocadorm_test;

class MockDatabaseHandler extends Mock implements DatabaseHandler {

  Future<List<Map>> retrieveAll(String table, List<String> columns, [List<PropertyFilter> filters]) {
    var entities = _entityRepository[table];

    return new Future.value(entities);
  }

  Future<Map> retrieveById(String table, List<String> columns, String pkColumn, Object pkValue) {
    var entities = _entityRepository[table],
    entity = entities.firstWhere((e) => e[pkColumn] == pkValue, orElse: () => null);

    return new Future.value(entity);
  }

  Future<Object> save(String table, List<String> columns, String pkColumn, Map data) {
    var entities = _entityRepository[table];

    entities.removeWhere((e) => e[pkColumn] == data[pkColumn]);

    if (!data.containsKey(pkColumn) || data[pkColumn] == null) {
      data[pkColumn] = entities.map((e) => e[pkColumn]).reduce(max) + 1;
    }

    entities.add(data);

    return new Future.value(data[pkColumn]);
  }

  Future delete(String table, String pkColumn, Object pkValue) {
    var entities = _entityRepository[table];

    entities.removeWhere((e) => e[pkColumn] == pkValue);

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
      { 'entity_b_id': 1, 'name': 'First EntityB', 'entity_c_id': 2 },
      { 'entity_b_id': 2, 'name': 'Second EntityB', 'entity_c_id': 1 },
      { 'entity_b_id': 3, 'name': 'Third EntityB', 'entity_c_id': 3 },
      { 'entity_b_id': 4, 'name': 'Fourth EntityB', 'entity_c_id': 1 },
      { 'entity_b_id': 5, 'name': 'Fifth EntityB', 'entity_c_id': null },
      { 'entity_b_id': 6, 'name': 'Sixth EntityB', 'entity_c_id': 1 },
  ];

  _entityRepository['entity_c'] = [
      { 'entity_c_id': 1, 'name': 'First EntityC' },
      { 'entity_c_id': 2, 'name': 'Second EntityC' },
      { 'entity_c_id': 3, 'name': 'Third EntityC' }
  ];
}
