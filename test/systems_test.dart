import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

class _MoveSystem extends EntityManagerSystem implements InitSystem, ExecuteSystem, CleanupSystem {
  Group _movable;
  @override
  init() {
    _movable = entityManager.group(all: [Position, Velocity]);
  }
  @override
  execute() {
    for (var e in _movable.entities) {
      var posX = e.get<Position>().x + e.get<Velocity>().x;
      var posY = e.get<Position>().y + e.get<Velocity>().y;
      e.set(Position(posX, posY));
    }
  }

  @override
  cleanup() {
    for (var e in _movable.entities) {
      var pos = e.get<Position>();
      if (pos.x > 100 || pos.y > 100) {
        e.destroy();
      }
    }
  }
}

class _InteractiveMoveSystem extends ReactiveSystem implements CleanupSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.added;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [Selected, Position]);

  @override
  executeWith(List<Entity> entities) {
    for (var e in entities) {
      var posX = e.get<Position>().x + 1;
      var posY = e.get<Position>().y + 1;
      e.set(Position(posX, posY));
    }
  }

  @override
  cleanup() {
    for (var e in entityManager.group(all: [Selected]).entities) {
      e.remove<Selected>();
    }
  }
}

class _TriggeredMoveSystem extends TriggeredSystem implements InitSystem{
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [Selected]);

  Group _movable;
  @override
  init() {
    _movable = entityManager.group(all: [Position]);
  }

  @override
  executeOnChange() {
    for (var e in _movable.entities) {
      var posX = e.get<Position>().x + 1;
      var posY = e.get<Position>().y + 1;
      e.set(Position(posX, posY));
    }
  }
}

void main() {
  test('Move System', (){
    var em = EntityManager();
    var root = RootSystem(em, [_MoveSystem()]);

    var e1 = em.createEntity()
    ..set(Position(0, 0))
    ..set(Velocity(1, 0));

    var e2 = em.createEntity()
    ..set(Name('e2'))
    ..set(Position(0, 0))
    ..set(Velocity(0, 1));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.isAlive, true);
    expect(e2.isAlive, true);

    expect(e1.get<Position>().x, 100);
    expect(e1.get<Position>().y, 0);

    expect(e2.get<Position>().x, 0);
    expect(e2.get<Position>().y, 100);

    root.execute();
    root.cleanup();

    expect(e1.isAlive, false);
    expect(e2.isAlive, false);

  });

  test('Interactive Move System', (){
    var em = EntityManager();
    var root = ReactiveRootSystem(em, [_InteractiveMoveSystem()]);

    var e1 = em.createEntity()
    ..set(Position(0, 0));

    var e2 = em.createEntity()
    ..set(Position(0, 0));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.isAlive, true);
    expect(e2.isAlive, true);

    expect(e1.get<Position>().x, 0);
    expect(e1.get<Position>().y, 0);

    expect(e2.get<Position>().x, 0);
    expect(e2.get<Position>().y, 0);

    e1 += Selected();

    root.execute();
    root.cleanup();

    expect(e1.get<Position>().x, 1);
    expect(e1.get<Position>().y, 1);

    expect(e2.get<Position>().x, 0);
    expect(e2.get<Position>().y, 0);

    e2 += Selected();

    root.execute();
    root.cleanup();

    expect(e1.get<Position>().x, 1);
    expect(e1.get<Position>().y, 1);

    expect(e2.get<Position>().x, 1);
    expect(e2.get<Position>().y, 1);

    expect(e1.hasT<Selected>(), false);
    expect(e2.hasT<Selected>(), false);

  });

  test('Triggered Move System', (){
    var em = EntityManager();
    var root = ReactiveRootSystem(em, [_TriggeredMoveSystem()]);

    var e1 = em.createEntity()
    ..set(Position(0, 0));

    var e2 = em.createEntity()
    ..set(Position(0, 0));

    root.init();

    for (var i = 0; i < 100; i++) {
      root.execute();
      root.cleanup();
    }

    expect(e1.get<Position>().x, 0);
    expect(e1.get<Position>().y, 0);

    expect(e2.get<Position>().x, 0);
    expect(e2.get<Position>().y, 0);


    for (var i = 0; i < 100; i++) {
      em.setUnique(Selected());
      root.execute();
      root.cleanup();
    }

    expect(e1.get<Position>().x, 100);
    expect(e1.get<Position>().y, 100);

    expect(e2.get<Position>().x, 100);
    expect(e2.get<Position>().y, 100);
  });
}