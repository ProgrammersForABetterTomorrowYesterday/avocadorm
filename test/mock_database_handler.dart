part of avocadorm_test;

class MockDatabaseHandler extends Mock implements DatabaseHandler {

  Future<List<Map>> retrieveAll(String table, List<String> columns) {
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

    if (data[pkColumn] == null) {
      data[pkColumn] = entities.reduce(max) + 1;
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
  _entityRepository[EntityA] = [
      { 'entityAId': 1, 'name': 'First EntityA', 'entityBId': 1 },
      { 'entityAId': 2, 'name': 'Second EntityA', 'entityBId': 2 },
      { 'entityAId': 3, 'name': 'Third EntityA', 'entityBId': null },
      { 'entityAId': 4, 'name': 'Fourth EntityA', 'entityBId': 3 },
      { 'entityAId': 5, 'name': 'Fifth EntityA', 'entityBId': 2 }
  ];

  _entityRepository[EntityB] = [
      { 'entityBId': 1, 'name': 'First EntityB', 'entityCId': 2 },
      { 'entityBId': 2, 'name': 'Second EntityB', 'entityCId': 1 },
      { 'entityBId': 3, 'name': 'Third EntityB', 'entityCId': 3 },
      { 'entityBId': 4, 'name': 'Fourth EntityB', 'entityCId': 1 },
      { 'entityBId': 5, 'name': 'Fifth EntityB', 'entityCId': null },
      { 'entityBId': 6, 'name': 'Sixth EntityB', 'entityCId': 1 },
  ];

  _entityRepository[EntityC] = [
      { 'entityCId': 1, 'name': 'First EntityC' },
      { 'entityCId': 2, 'name': 'Second EntityC' },
      { 'entityCId': 3, 'name': 'Third EntityC' }
  ];
}
