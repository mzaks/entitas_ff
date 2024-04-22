import 'package:meta/meta.dart';

/// Defines an interface which every component class needs to implement.
///
/// ### Example
///
///     class NameComponent implements Component {
///       final String value;
///       Name(this.value);
///     }
@immutable
abstract class Component {}

/// Defines an interface which every unique component class needs to implement.
/// Unique means that there can be only one instance of this component set on an [Entity] per [EntityManager]
///
/// ### Example
///
///     class SelectedComponent implements UniqueComponent {}
/// 
@immutable
abstract class UniqueComponent extends Component {}

/// Interface which you need to implement if you want to observe changes on an [Entity] instance
abstract class EntityObserver {
  /// Called after the destroy method is called on the entity and all components are removed.
  destroyed(Entity e);
  /// Called after a component was added exchanged or removed from an [Entity] instance.
  /// When a component was added, it is reflected in `newC` and `oldC` is `null`.
  /// When a component was removed, old component is reflected in `oldC` and `newC` is `null`.
  /// When a component was exchanged, old and new components are refelcted in `oldC` and `newC` respectively.
  exchanged(Entity e, Component? oldC, Component? newC);
}

/// Class which represents an entity instance.
/// An instance of an entity can be created only through an [EntityManger].
/// ### Example
///   EntityManager em = EntityManager();
///   Entity e = em.createEntity();
class Entity {
  /// Creation Index is assigned by the [EntityManager] on creation and can be seen as a sequential id of an entity.
  final int creationIndex;
  // Main observer is a reference to the [EntityManager]
  final EntityObserver _mainObserver;
  // constructor
  Entity({required this.creationIndex, required EntityObserver mainObserver}): _mainObserver = mainObserver;
  // Holding all components map through their type.
  Map<Type, Component> _components = Map();
  // Holding all observers.
  Set<EntityObserver> _observers = Set();
  /// Indicator if the entity was already destroyed.
  /// Checked internally on entity mutating operations.
  var isAlive = true;

  /// Returns component instance by type or `null` if not present.
  T? getOrNull<T extends Component>() {
    Component? c = _components[T];
    if (c == null) { return null; }
    return c as T;
  }

  /// Returns component instance by type
  T get<T extends Component>() {
    return _components[T] as T;
  }

  /// Adds component instance to the entity.
  /// If the entity already has a component of the same instance, the component will be replaced with provided one.
  /// After the component is set, all observers are notified.
  /// Calling this operator on a destroyed entity is considerered an error.
  Entity operator + (Component c) {
    assert(isAlive, "Calling `+` Component on destroyed entity");
    Component? oldC = _components[c.runtimeType];
    _components[c.runtimeType] = c;
    _mainObserver.exchanged(this, oldC, c);
    for (var o in _observerList) {
      o.exchanged(this, oldC, c);
    }
    return this;
  }

  /// Internally just calls the `+` operator.
  /// Introduced inorder to support cascade notation.
  void set(Component c) {
    var _ = this + c;
  }

  /// Removes component from the entity.
  /// If component of the given type was not present on the entity, nothing happens.
  /// The observers are notified only if there was a component removed.
  /// Calling this operator on a destroyed entity is considerered an error.
  Entity operator - (Type t) {
    assert(isAlive, "Calling `-` Component on destroyed entity");
    var c = _components[t];
    if (c != null) {
      _components.remove(t);
      _mainObserver.exchanged(this, c, null);
      for (var o in _observerList) {
        o.exchanged(this, c, null);
      }
    }

    return this;
  }

  /// Internally just calls the `-` operator.
  /// Introduced inorder to support cascade notation.
  void remove<T extends Component>() {
    var _ = this - T;
  }

  /// Check if entity hold a component of the given type.
  bool has(Type t) {
    return _components.containsKey(t);
  }

  /// Same as `has` method just with generics.
  bool hasT<T extends Component>() {
    return _components.containsKey(T);
  }

  /// Adds observer to the entity which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  addObserver(EntityObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Remove an observer form the [Set] of observers.
  removeObserver(EntityObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Destroy an entity which will lead to following steps:
  /// 1. Remove all components
  /// 2. Notify all observers
  /// 3. Remove all observers
  /// 4. Set `isAlive` to `false`.
  destroy() {
    for (var comp in _components.values.toList()) {
      var _ = this - comp.runtimeType;
    }
    _mainObserver.destroyed(this);
    for (var o in _observerList) {
      o.destroyed(this);
    }
    _observers.clear();
    __observerList = null;
    isAlive = false;
  }

  /// An entity is equal to other if `creationIndex` and `_mainObserver` are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Entity &&
              runtimeType == other.runtimeType &&
              creationIndex == other.creationIndex &&
              identical(_mainObserver, other._mainObserver);

  /// We use `creationIndex` as hashcode
  @override
  int get hashCode => creationIndex;

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<EntityObserver>? __observerList;
  List<EntityObserver> get _observerList {
    if (__observerList == null ) {
      __observerList = List.unmodifiable(_observers);
    }
    
    return __observerList!;
  }
}

/// EntityMatcher can be understood as a query. It can be used to checks if an [Entity] complies with provided rules.
/// ### Example
///   var matcher = EntityMatcher(all: [A, B], any: [C, D] none: [E])
/// For an neity to pass the given `matcher` it needs to contain components of type `A` and `B`. Either `C` or `D`. And no `E`.
/// The provided lists `all`, `any` and `none` are internally translated to a [Set]. This means that order and occurance of duplications is not important.
/// If you provide the `none` list, you have to provide either `all` or `any` none empty list of component types.
class EntityMatcher {
  final Set<Type> _all;
  final Set<Type> _any;
  final Set<Type> _none;

  EntityMatcher({List<Type>? all, List<Type>? any, List<Type>? none}):
      _all = Set.of(all ?? []),
      _any = Set.of(any ?? []),
      _none = Set.of(none ?? []);


  /// Checks if the [Entity] contains necessary components.
  bool matches(Entity e) {
    for (var t in _all) {
      if (e.has(t) == false) {
        return false;
      }
    }
    for (var t in _none) {
      if (e.has(t)) {
        return false;
      }
    }
    if (_any.isEmpty) {
      return true;
    }
    for (var t in _any) {
      if (e.has(t)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if `all`, `any` or `none` contains given type.
  bool containsType(Type t) {
    return _all.contains(t) || _any.contains(t) || _none.contains(t);
  }

  /// Matcher are equal if their `all`, `any`, `none` sets overlap.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          (other is EntityMatcher &&
              runtimeType == other.runtimeType &&
              _all.length == other._all.length &&
              _any.length == other._any.length &&
              _none.length == other._none.length &&
              _all.difference(other._all).isEmpty &&
              _any.difference(other._any).isEmpty &&
              _none.difference(other._none).isEmpty);

  /// Different matchers with same `all`, `any`, `none` need to return equal hash code.
  @override
  int get hashCode {
    var a = _all.fold(0, (int sum, Type t) =>  t.hashCode ^ sum);
    var b = _any.fold(a << 4, (int sum, Type t) =>  t.hashCode ^ sum);
    var c = _none.fold(b << 4, (int sum, Type t) =>  t.hashCode ^ sum);
    return c;
  }
}

/// Interface which you need to implement, if you want to observe changes on [Group] instance
abstract class GroupObserver {
  added(Group group, Entity entity);
  updated(Group group, Entity entity);
  removed(Group group, Entity entity);
}

/// Group represent a collection of entities, which match a given [EntityMatcher] and is always up to date.
/// It can be instantiated only through an instance of [EntityManager].
/// ### Example
///   EntityManager em = EntityManager();
///   Group g = em.group(all: [Name, Age]);
/// 
/// Always up to date means that if we create an entity `e` and add components `Name` and `Age` to it, the entity will directly become part of the group g.
/// 
/// ### Example
///   Entity e = em.createEntity();
///   e += Name("Max");
///   e += Age(37);
///   // e is now accessible through g.
/// 
///   e -= Name;
///   // e is not part of g any more.
/// 
/// Groups are observable, see `addObserver`, `removeObserver`.
/// In order to access the entities of the group you need to call `entities` getter
class Group implements EntityObserver {
  // References to entities matching the `matcher` are stored as a [Set]
  Set<Entity> _entities = new Set();
  // References to group observers.
  Set<GroupObserver> _observers = new Set();
  /// Matcher which is used to check the compliance of the entities.
  final EntityMatcher matcher;

  Group({required this.matcher});

  /// Adds observer to the group which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  addObserver(GroupObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Remove observer form the Group.
  removeObserver(GroupObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Lets user check if the group is empty.
  /// Does the check directly on the underlying data structure, without creation of unnecessary copies.
  bool get isEmpty => _entities.isEmpty;

  // Internal method called only by [EntityManager], to fill up a newly instantited group with exisitng matching entities.
  _addEntity(Entity e) {
    _entities.add(e);
    for (var o in _observerList) {
      o.added(this, e);
    }
  }

  /// Group is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  destroyed(Entity e) {
    e.removeObserver(this);
  }

  /// Group is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
    final isRelevantAdd = newC != null && matcher.containsType(newC.runtimeType);
    final isRelevantRemove = oldC != null && matcher.containsType(oldC.runtimeType);
    if ((isRelevantAdd || isRelevantRemove) == false) {
      return;
    }
    if (matcher.matches(e)) {
      if (_entities.add(e)) {
        __entities = null;
        for (var o in _observerList) {
          o.added(this, e);
        }
      } else {
        for (var o in _observerList) {
          o.updated(this, e);
        }
      }
    } else {
      if (_entities.remove(e)) {
        __entities = null;
        for (var o in _observerList) {
          o.removed(this, e);
        }
        
      }
    }
  }

  /// Creates a list of matching entities.
  /// This List contains the copy of references to the matching entities.
  /// As it is a copy, it is safe to use in a mutating loop.
  /// ### Example
  ///   for(var e in group.entities) {
  ///     e.destroy();
  ///   }
  /// As we call `destroy` on the entity `e` it will imideatly exit the group, but it is ok as we are iterating on list of entities and not on the group directly. 
  List<Entity> get entities {
    if (__entities == null) {
      __entities = List.unmodifiable(_entities);
    }
    return __entities!;
  }
  List<Entity>? __entities;

  /// Helper method to perform destruction of all entities in the group.
  destroyAllEntities() {
    for (var e in entities) {
      e.destroy();
    }
  }

  /// Groups are equal if their matchers are equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Group &&
              runtimeType == other.runtimeType &&
              matcher == other.matcher;

  /// Hash code of the group is equal to hash code of its matcher.
  @override
  int get hashCode => matcher.hashCode;

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<GroupObserver>? __observerList; //  = List(0)
  List<GroupObserver> get _observerList {
    if (__observerList == null) {
      __observerList = List.unmodifiable(_observers);
    }
    
    return __observerList!;
  }
}

/// Interface which you need to implement, if you want to observe changes on [EntityManager] instance
abstract class EntityManagerObserver {
  entityCreated(Entity e);
}

/// EntityManager is the central peace of entitas_ff. It can be understood as a central managing data structure.
/// It manages the lifecycle of [Entity] instances and stores instances of [Group], which we use to access entities with certain qualities.
/// EntityManager is observable, see `addObserver`, `removeObserver`.
class EntityManager implements EntityObserver {
  // sequential index of all created entities.
  var _currentEntityIndex = 0;
  // holds all entities mapped by creation id. 
  final Map<int, Entity> _entities = Map();
  // holds all groups mapped by entity matcher.
  final Map<EntityMatcher, Group> _groupsByMatcher = Map();
  // holds all unique entities mapped to unique component type
  final Map<Type, Entity> _uniqueEntities = Map();
  // holds observers
  final Set<EntityManagerObserver> _observers = Set();

  /// The only way how users can create new entities.
  /// ### Example
  ///   EntityManager em = EntityManager();
  ///   Entity e = em.createEntity();
  ///   
  /// During creation the entity will receive a creation index id and it will receive all group as observers, becuase every entity might become part of the group at some point.
  /// At the end it will notify own observers that an eneitty was created.
  Entity createEntity() {
    var e = Entity(creationIndex: _currentEntityIndex, mainObserver: this);
    _entities[_currentEntityIndex] = e;
    _currentEntityIndex++;
    for (var g in _groupsByMatcher.values) {
      e.addObserver(g);
    }
    for (var o in _observerList) {
      o.entityCreated(e);
    }
    return e;
  }

  /// Group is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  destroyed(Entity e) {
    _entities.remove(e.creationIndex);
  }

  /// Group is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
    if (newC is UniqueComponent || oldC is UniqueComponent) {
      if (oldC != null && newC == null) {
        _uniqueEntities.remove(oldC.runtimeType);
      }
      if (newC != null) {
        var prevE = _uniqueEntities[newC.runtimeType];
        if (prevE != null) {
          assert(prevE == e, "You added unique component to a second entity");
        } else {
          _uniqueEntities[newC.runtimeType] = e;
        }
      }
    }
  }

  /// Lets user set a unique component, which either exchanges a component on already existing entity, or creates a new entity and sets component on it.
  /// [Entity] which holds the unique component is returned
  Entity setUnique(UniqueComponent c) {
    var e = _uniqueEntities[c.runtimeType] ?? createEntity();
    e += c;
    return e;
  }

  /// Sets a unique component on a provided [Entity].
  /// As there can be only one instance of a unique component type, it will first remove old unqiue component.
  /// ### Example
  ///   Entity e1 = entityManager.setUnique(Selected());
  ///   Entity e2 = entityManager.createEntity();
  ///   entityManager.setUniqueOnEntity(Selected(), e2);
  ///   assert(e1.has(Selected) == false);
  ///   assert(e2.has(Selected) == true);
  Entity setUniqueOnEntity(UniqueComponent c, Entity e) {
    var prevE = _uniqueEntities[c.runtimeType];
    if (prevE != null) {
      prevE -= c.runtimeType;
    }

    e += c;
    return e;
  }

  /// Removes unique component on an entity.
  /// If entity does not have any other components after removal, it is destroyed.
  removeUnique<T extends UniqueComponent>() {
    var e = _uniqueEntities[T];
    if (e == null) {
      return;
    }
    e.remove<T>();
    if (e._components.length == 0) {
      e.destroy();
    }
  }

  /// Returns the component instance or throws an exception if component is `null`.
  T getUnique<T extends UniqueComponent>() {
    final component = _uniqueEntities[T]?.getOrNull<T>();
    if (component == null) throw new Exception("Component is null");
    return component;
  }

  /// Returns the component instance or `null`.
  T? getUniqueOrNull<T extends UniqueComponent>() {
    return _uniqueEntities[T]?.getOrNull<T>();
  }

  /// Returns [Entity] instance which hold the unique component, or throws an exception if component is `null`.
  Entity getUniqueEntity<T extends UniqueComponent>() {
    final entity = _uniqueEntities[T];
    if (entity == null) throw new Exception("Entity is null");
    return entity;
  }

  /// Returns [Entity] instance which hold the unique component, or `null`.
  Entity? getUniqueEntityOrNull<T extends UniqueComponent>() {
    return _uniqueEntities[T];
  }

  /// Convenience method to call `groupMatching` method.
  /// Creates an instance of [EntityMatcher]
  Group group({List<Type>? all, List<Type>? any, List<Type>? none}) {
    var matcher = EntityMatcher(all: all, any: any, none: none);
    return groupMatching(matcher);
  }

  /// Returns a group backed by provided matcher.
  /// [EntityMatcher] instance should not be `null`.
  /// It is safe to call this method multiple times as the groups are cached and user will receive same cached instance.
  /// If a new group needs to be created it will be directly populated by existing matching entities.
  Group groupMatching(EntityMatcher matcher) {
    var group = _groupsByMatcher[matcher];
    if (group != null) {
      return group;
    }
    group = Group(matcher: matcher);
    for (var e in _entities.values) {
      e.addObserver(group);
      if (matcher.matches(e)) {
        group._addEntity(e);
      }
    }
    _groupsByMatcher[matcher] = group;
    return group;
  }

  /// Adds observer to the entity manager which will be notified on every mutating action.
  /// Observers are stored in a [Set].
  addObserver(EntityManagerObserver o) {
    _observers.add(o);
    __observerList = null;
  }

  /// Removes observer.
  removeObserver(EntityManagerObserver o) {
    _observers.remove(o);
    __observerList = null;
  }

  /// Return a List with reference copy of all entities.
  List<Entity> get entities => List.unmodifiable(_entities.values);

  // Caching the observer list, so that when observers are called they can safely remove themselves as observers
  List<EntityManagerObserver>? __observerList; //= List(0);
  List<EntityManagerObserver> get _observerList {
    if (__observerList == null) {
      __observerList = List.unmodifiable(_observers);
    }
    
    return __observerList!;
  }
}

/// Defines a function which given a [Component] instance can produce a key which is used in a [Map]
typedef T KeyProducer<C extends Component, T>(C c);

/// A class which let users map entities against values of a component.
/// ### Example
///     var nameMap = EntityMap<Name, String>(em, (name) => name.value );
/// 
/// An [EntityMap] maps only one entity to a value component.
/// A situation, where multiple components are matching the same [EntityMap] key is considered an error.
/// Please use [EntityMultiMap] to cover such scenario.
class EntityMap<C extends Component, T> implements EntityObserver, EntityManagerObserver {
  // holds entities entities mapped against key
  final Map<T, Entity> _entities = Map();
  // holds key producer instance
  final KeyProducer<C, T> _keyProducer;
  EntityMap(EntityManager entityManager, this._keyProducer) {
    entityManager.addObserver(this);
    for (var e in entityManager.entities) {
      e.addObserver(this);
      if (e.has(C)) {
        exchanged(e, null, e.getOrNull<C>());
      }
    }
  }

  /// EntityMap is an [EntityManagerListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  entityCreated(Entity e) {
    e.addObserver(this);
  }

  /// EntityMap is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  destroyed(Entity e) {
    e.removeObserver(this);
  }

  /// EntityMap is an [EntityListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
    if(oldC is C) {
      _entities.remove(_keyProducer(oldC));
    }
    if (newC is C) {
      assert(_entities[_keyProducer(newC)] == null, "Multiple values for same key are prohibited in EntityMap, please use EntityMultiMap instead.");
      _entities[_keyProducer(newC)] = e;
    }
  }

  /// Get an [Entity] instance or `null` based on provided key.
  Entity? get(T key) {
    return _entities[key];
  }

  /// Get an [Entity] instance or `null` based on provided key.
  Entity? operator [](T key) {
    return _entities[key];
  }
}

/// A class which let users map entities against values of a component.
/// ### Example
///     var ageMap = EntityMultiMap<Age, int>(em, (name) => name.value);
/// 
/// It is different from [EntityMap] in a way that it lets multiple entities match agains the same key.
class EntityMultiMap<C extends Component, T> implements EntityObserver, EntityManagerObserver {
  // holds list of entities mapped against key
  final Map<T, List<Entity>> _entities = Map();
  // holds key producer
  final KeyProducer<C, T> _keyProducer;
  EntityMultiMap(EntityManager entityManager, this._keyProducer) {
    entityManager.addObserver(this);
    for (var e in entityManager.entities) {
      e.addObserver(this);
      if (e.has(C)) {
        exchanged(e, null, e.getOrNull<C>());
      }
    }
  }

  /// EntityMultiMap is an [EntityManagerListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  entityCreated(Entity e) {
    e.addObserver(this);
  }

  /// EntityMultiMap is an [EntityManagerListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  destroyed(Entity e) {
    e.removeObserver(this);
  }

  /// EntityMultiMap is an [EntityManagerListener], this is an implementation of this protocol.
  /// Please don't use manually.
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
    if(oldC is C) {
      _entities[_keyProducer(oldC)]?.remove(e);
    }
    if (newC is C) {
      var list = _entities[_keyProducer(newC)] ?? List.empty(growable: true);
      list.add(e);
      _entities[_keyProducer(newC)] = list;
    }
  }

  /// Get a list of [Entity] instances or an empty list based on provided key.
  List<Entity> get(T key) {
    return List.unmodifiable(_entities[key] ?? List.empty());
  }

  /// Get a list of [Entity] instances or an empty list based on provided key.
  List<Entity> operator [](T key) {
    return List.unmodifiable(_entities[key] ?? List.empty());
  }
}
