import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'state.dart';
import 'behaviour.dart';

/// Widget which holds a reference to an [EntityManager] instance and can expose it to children.
/// If an instance of [RootSystem] is provided. It will be executed appropriately.
class EntityManagerProvider extends InheritedWidget {
  /// [EntityManager] instance provided on intialisation.
  final EntityManager entityManager;
  /// [RootSystem] instance provided on intialisation. Can be `null`.
  final RootSystem systems;

  EntityManagerProvider({
    Key key,
    @required EntityManager entityManager,
    this.systems,
    @required Widget child,
  })  : assert(child != null),
        assert(entityManager != null),
        entityManager = entityManager,
        super(key: key, child: systems != null ? _RootSystemWidget(child: child, systems: systems) : child);

  /// Returns [EntityManagerProvider] if it is part of your widget tree. Otherwise returns `null`.
  static EntityManagerProvider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(EntityManagerProvider) as EntityManagerProvider;
  }

  @override
  bool updateShouldNotify(EntityManagerProvider oldWidget) => oldWidget.entityManager != entityManager;
}

/// Internal widget which is used to tick along the instance of [RootSystem].
class _RootSystemWidget extends StatefulWidget{
  final Widget child;
  final RootSystem systems;
  const _RootSystemWidget({
        Key key,
        @required this.child,
        @required this.systems
  }) : assert(systems != null), super(key: key);

  @override
  State<StatefulWidget> createState() => _RootSystemWidgetState();
}

/// State class of internal widget [_RootSystemWidget]
class _RootSystemWidgetState extends State<_RootSystemWidget> with SingleTickerProviderStateMixin{

  Ticker _ticker;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(tick);
    _ticker.start();
    widget.systems.init();
  }


  @override
  void dispose() {
    _ticker.stop();
    super.dispose();
  }

  tick(Duration elapsed) {
    widget.systems.execute();
    widget.systems.cleanup();
  }

}

/// Defines a function which given an [EntityManager] instance returns a reference to an [Entity].
typedef Entity EntityProvider(EntityManager entityManager);
/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityBackedWidgetBuilder(Entity e, BuildContext context);

/// Widget which observes an entity and rebuilds it's child when the entity has changed.
class EntityObservingWidget extends StatefulWidget {
  /// Function which returns an entity the widget should observe.
  final EntityProvider provider;
  /// Function which is builds widgets child, based on [Entity] and [BuildContext].
  final EntityBackedWidgetBuilder builder;

  const EntityObservingWidget({Key key, @required this.provider, @required this.builder}) : super(key: key);

  @override
  State<StatefulWidget> createState() => EntityObservingWidgetState();

}

/// State class for [EntityObservingWidget].
class EntityObservingWidgetState extends State<EntityObservingWidget> implements EntityObserver {
  // holds reference to entity under observation
  Entity _entity;
  // marks if `setState` was already called
  var _isDirty = false;

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    var manager = EntityManagerProvider.of(context).entityManager;
    assert(manager != null, "$widget is not a child of EntityObservingWidget");
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    if (_entity != null) {
      _entity.addObserver(this);
    }
    return widget.builder(_entity, context);
  }

  /// Implementation of [EntityObserver]
  @override
  destroyed(Entity e) {
    _update();
  }

  /// Implementation of [EntityObserver]
  @override
  exchanged(Entity e, Component oldC, Component newC) {
    _update();
  }

  _update() {
    if (_isDirty == false) {
      _isDirty = true;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _entity?.removeObserver(this);
    super.dispose();
  }
}

/// Defines a function which given a [Group] instance and [BuildContext] returns an instance of a [Widget].
typedef Widget GroupBackedWidgetBuilder(Group group, BuildContext context);

/// Widget which observes a group and rebuilds it's child when the group has changed.
class GroupObservingWidget extends StatefulWidget {
  /// holds reference to provided matcher
  final EntityMatcher matcher;
  /// holds reference to function which builds the child [Widget]
  final GroupBackedWidgetBuilder builder;

  const GroupObservingWidget({Key key, @required this.matcher, @required this.builder}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GroupObservingWidgetState();

}

class GroupObservingWidgetState extends State<GroupObservingWidget> implements GroupObserver {
  // holds reference to group under observation
  Group _group;
  // marsk if `setState` was already called 
  var _isDirty = false;

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    var manager = EntityManagerProvider.of(context).entityManager;
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher);
    _group.addObserver(this);

    return widget.builder(_group, context);
  }

  @override
  void dispose() {
    _group.removeObserver(this);
    super.dispose();
  }

  /// Implementation of [GroupObserver]
  @override
  added(Group group, Entity entity) {
    _update();
  }

  /// Implementation of [GroupObserver]
  @override
  removed(Group group, Entity entity) {
    _update();
  }

  /// Implementation of [GroupObserver]
  @override
  updated(Group group, Entity entity) {
    _update();
  }

  _update() {
    if (_isDirty == false) {
      _isDirty = true;
      setState(() {});
    }
  }
}