import 'package:meta/meta.dart';
import 'state.dart';

/// An inteface which user need to implement in order to mark a class as a system.
abstract class System {
}

/// An interface which user needs to implement in order to mark a class an execute system.
abstract class ExecuteSystem extends System {
  execute();
}

/// An interface which user needs to implement in order to mark a class an init system.
abstract class InitSystem extends System {
  init();
}

/// An interface which user needs to implement in order to mark a class a cleanup system.
abstract class CleanupSystem extends System {
  cleanup();
}

/// An abstract class which user should implement if they want their systems to hold a reference to [EntityManager]
abstract class EntityManagerSystem extends System {
  EntityManager __manager;
  @mustCallSuper
  set _manager(EntityManager m){
    __manager = m;
  }
  EntityManager get entityManager => __manager;
}

/// Enum characterising the group change events.
/// Used primarily by [ReactiveSystem]
/// `any` every event is matching.
enum GroupChangeEvent {
  added, updated, removed, addedOrUpdated, any
}

/// Abstract class which users must implement if they want to define a system which is triggered when the observed group has changed.
/// Triggered means that `executeWith` method is called, provided with a list of all entities which changed after last execution.
/// ### Example
///     class AddItemToShoppingCartSystem extends ReactiveSystem {
///       @override
///       executeWith(List<Entity> entities) {
///         for (var e in entities) {
///           var newCount = (e.get<CountComponent>()?.value ?? 0) + 1;
///           e += CountComponent(newCount);
///         }
///       }
///
///       @override
///       GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
///       @override
///       EntityMatcher get matcher => EntityMatcher(all: [AddToShoppingCartComponent]);
///     }
abstract class ReactiveSystem extends EntityManagerSystem implements ExecuteSystem, GroupObserver {
  // holds the group the reactive system is observing
  Group _group;
  // holds references to entities which changed since last execution
  Set<Entity> _collectedEntities = Set();

  ReactiveSystem();

  /// Implementation of [ExecuteSystem] interface.
  /// Calls `executeWith` only if `_collectedEntities` is not empty.
  /// Clears `_collectedEntities` after `executeWith` call.
  @override
  execute() {
      if (_collectedEntities.isNotEmpty) {
        executeWith(_collectedEntities.toList());
        _collectedEntities.clear();
      }
  }

  /// Override of [EntityManagerSystem] class method.
  /// This is where the [Group] instance is provided and the system starts observing the group. 
  @override
  set _manager(EntityManager m) {
    super._manager = m;
    assert(matcher != null, "Matcher was not specified in system " + this.runtimeType.toString());
    _group = __manager.groupMatching(matcher);
    _group.addObserver(this);
  }

  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent].
  /// Please don't call directly.
  added(Group group, Entity entity) {
    if (event == GroupChangeEvent.added || event == GroupChangeEvent.addedOrUpdated || event == GroupChangeEvent.any) {
      _collectedEntities.add(entity);
    }
  }
  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent].
  /// Please don't call directly.
  updated(Group group, Entity entity) {
    if (event == GroupChangeEvent.updated || event == GroupChangeEvent.addedOrUpdated || event == GroupChangeEvent.any) {
      _collectedEntities.add(entity);
    }
  }
  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent].
  /// Please don't call directly.
  removed(Group group, Entity entity) {
    if (event == GroupChangeEvent.removed || event == GroupChangeEvent.any) {
      _collectedEntities.add(entity);
    }
  }

  /// Abstract methods user needs to implement. See example on the class definition.
  executeWith(List<Entity> entities);
  /// Abstract getter user needs to implement. See example on the class definition.
  EntityMatcher get matcher;
  /// Anbstract getter user needs to implement. See example on the class definition.
  GroupChangeEvent get event;
}

/// Abstract class which users must implement if they want to define a system which is triggered when the observed group has changed.
/// In comparison to [ReactiveSystem] a triggered system does not collect entities which changed after the last execution.
/// The are many cases where we are only interested in the change itself and not in the entities which lead to this change.
/// With this in mind [TriggeredSystem] provides a light weight alternative to [ReactiveSystem]
/// 
/// ### Example
///     class ComputeTotalSumSystem extends TriggeredSystem {
///
///       @override
///       GroupChangeEvent get event => GroupChangeEvent.any;
///
///       @override
///       EntityMatcher get matcher => EntityMatcher(all:[CountComponent, AmountInSelectedCurrencyComponent]);
///
///       @override
///       executeOnChange() {
///         final sum = entityManager.group(all: [CountComponent, AmountInSelectedCurrencyComponent]).entities.fold(0.0, (sum, e) => sum
///                     + (e.get<AmountInSelectedCurrencyComponent>()?.value ?? 0.0)
///                     * (e.get<CountComponent>()?.value ?? 0)
///         );
///         entityManager.setUnique(TotalAmountComponent(sum));
///       }
///
///     }
abstract class TriggeredSystem extends EntityManagerSystem implements ExecuteSystem, GroupObserver {
  // holds the group the system is observing
  Group _group;
  // holds the flag if the system should be executed this time
  bool _triggered = false;

  TriggeredSystem();

  /// Implementation of [ExecuteSystem] interface.
  /// Calls `executeOnChange` only if `_triggered` is set to true.
  /// Sets `_triggered` to false after `executeOnChange` called.
  @override
  execute() {
      if (_triggered) {
        executeOnChange();
        _triggered = false;
      }
  }

  /// Override of [EntityManagerSystem] class method.
  /// This is where the [Group] instance is provided and the system starts observing the group. 
  @override
  set _manager(EntityManager m) {
    super._manager = m;
    assert(matcher != null, "Matcher was not specified in system " + this.runtimeType.toString());
    _group = __manager.groupMatching(matcher);
    _group.addObserver(this);
  }

  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent] and sets `_triggered` value accordingly.
  /// Please don't call directly.
  added(Group group, Entity entity) {
    if (event == GroupChangeEvent.added || event == GroupChangeEvent.addedOrUpdated || event == GroupChangeEvent.any) {
      _triggered = true;
    }
  }
  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent] and sets `_triggered` value accordingly.
  /// Please don't call directly.
  updated(Group group, Entity entity) {
    if (event == GroupChangeEvent.updated || event == GroupChangeEvent.addedOrUpdated || event == GroupChangeEvent.any) {
      _triggered = true;
    }
  }
  /// Implementation of [GroupObserver].
  /// Processes changes in respect to provided [GroupChangeEvent] and sets `_triggered` value accordingly.
  /// Please don't call directly.
  removed(Group group, Entity entity) {
    if (event == GroupChangeEvent.removed || event == GroupChangeEvent.any) {
      _triggered = true;
    }
  }

  /// Abstract methods user needs to implement. See example on the class definition.
  executeOnChange();
  /// Abstract getter user needs to implement. See example on the class definition.
  EntityMatcher get matcher;
  /// Abstract getter user needs to implement. See example on the class definition.
  GroupChangeEvent get event;
}

/// RootSystem can be considered as a parent node in an hierarchy of systems.
/// It implements all the important system interfaces and is executed as all of them.
/// On creation [RootSystem] is provided with an instance of [EntityManager] and a list of child systems.
/// If a child is extending the [EntityManagerSystem] it will get the [EntityManager] instance injected.
/// The children are devided into lists according to the interfaces they implement.
/// When the root system is called as [InitSystem], it will delegate the call to it's children which also implement [InitSystem] interface.
/// Same applies to [ExecuteSystem] and [CleanupSystem] calls and implementing children.
class RootSystem implements ExecuteSystem, InitSystem, CleanupSystem {
  // holds reference to child systems which implement [InitSystem] interface
  final List<InitSystem> _initSystems = [];
  // holds reference to child systems which implement [ExecuteSystem] interface
  final List<ExecuteSystem> _executeSystems = [];
  // holds reference to child systems which implement [CleanupSystem] interface
  final List<CleanupSystem> _cleanupSystems = [];
  // holds reference to [EntityManager] instance
  final EntityManager _entityManager;

  RootSystem(this._entityManager, List<System> systems) {
    for (var s in systems) {
      if (s is EntityManagerSystem) {
        s._manager = _entityManager;
      }
      if (s is InitSystem) {
        _initSystems.add(s);
      }
      if (s is ExecuteSystem) {
        _executeSystems.add(s);
      }
      if (s is CleanupSystem) {
        _cleanupSystems.add(s);
      }
    }
  }

  /// Implementation of [InitSystem]
  /// Delegates the call to its children.
  @override
  init() {
    for (var s in _initSystems){
      s.init();
    }
  }

  /// Implementation of [ExecuteSystem]
  /// Delegates the call to its children.
  @override
  execute() {
    for (var s in _executeSystems){
      s.execute();
    }
  }

  /// Implementation of [CleanupSystem]
  /// Delegates the call to its children.
  @override
  cleanup() {
    for (var s in _cleanupSystems) {
      s.cleanup();
    }
  }
}

/// ReactiveRootSystem is a [RootSystem] which triggeres it's child systems only if a state of an [EntityManager] or of any [Entity] have changed.
/// Users might use this implementation of [RootSystem] in order to minimise the amount of `execute` calls performed on every tick.
/// User can provide a black list of component types which are excluded as meaningful execution triggeres.
class ReactiveRootSystem extends RootSystem implements EntityManagerObserver, EntityObserver {

  // holds component types which are not considered as triggerable change
  Set<Type> _blackList;
  // holds a flag which defines if `execute` method on children should be called
  var _shouldExecute = false;
  // holds a flag which defines if `cleanup` method on children should be called
  var _shouldCleanup = false;

  ReactiveRootSystem(EntityManager entityManager, List<System> systems, {List<Type> blackList}) : super(entityManager, systems) {
    _blackList = Set.from(blackList ?? []);
    entityManager.addObserver(this);
  }

  /// Implementation of [EntityManagerObserver].
  /// Please don't call directly.
  @override
  entityCreated(Entity e) {
    e.addObserver(this);
  }

  /// Implementation of [EntityObserver].
  /// Please don't call directly.
  @override
  destroyed(Entity e) {
    e.removeObserver(this);
  }

  /// Implementation of [EntityObserver].
  /// Please don't call directly.
  @override
  exchanged(Entity e, Component oldC, Component newC) {
    if (_shouldExecute) {
      return;
    }
    if(oldC != null && _blackList.contains(oldC.runtimeType)) {
      return;
    }
    if(newC != null && _blackList.contains(newC.runtimeType)) {
      return;
    }
    _shouldExecute = true;
    _shouldCleanup = true;
  }

  /// Overide of [ExecuteSystem] interface on [RootSystem]
  /// Calls `super` only if `_shouldExecute` is marked as true.
  /// Sets `_shouldExecute` to `false`.
  @override
  execute() {
    if(_shouldExecute) {
      _shouldExecute = false;
      super.execute();
    }
  }

  /// Overide of [CleanupSystem] interface on [RootSystem]
  /// Calls `super` only if `_shouldCleanup` is marked as true.
  /// Sets `_shouldCleanup` to `false`.
  @override
  cleanup() {
    if(_shouldCleanup) {
      _shouldCleanup = false;
      super.cleanup();
    }
  }
}