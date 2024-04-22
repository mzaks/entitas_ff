import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'state.dart';
import 'behaviour.dart';

/// Widget which holds a reference to an [EntityManager] instance and can expose it to children.
/// If an instance of [RootSystem] is provided. It will be executed appropriately.
class EntityManagerProvider extends InheritedWidget {
  /// [EntityManager] instance provided on initialization.
  final EntityManager entityManager;
  /// [RootSystem] instance provided on initialization. Can be `null`.
  final RootSystem? systems;

  EntityManagerProvider({
    required EntityManager entityManager,
    this.systems,
    required Widget child,
  })  :
        entityManager = entityManager,
        super(child: systems != null ? _RootSystemWidget(child: child, systems: systems) : child);

  /// Returns [EntityManagerProvider] if it is part of your widget tree. Otherwise returns `null`.
  static EntityManagerProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EntityManagerProvider>() as EntityManagerProvider;
  }

  @override
  bool updateShouldNotify(EntityManagerProvider oldWidget) => oldWidget.entityManager != entityManager;
}

/// Internal widget which is used to tick along the instance of [RootSystem].
class _RootSystemWidget extends StatefulWidget{
  final Widget child;
  final RootSystem systems;
  const _RootSystemWidget({
        required this.child,
        required this.systems
  }): super();

  @override
  State<StatefulWidget> createState() => _RootSystemWidgetState();
}

/// State class of internal widget [_RootSystemWidget]
class _RootSystemWidgetState extends State<_RootSystemWidget> with SingleTickerProviderStateMixin{
  late Ticker _ticker;

  @override
  Widget build(BuildContext context) => widget.child;

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
typedef Entity? EntityProvider(EntityManager entityManager);
/// Defines a function which given an [Entity] (can be `null`) and [BuildContext] returns a an instance of [Widget].
typedef Widget EntityBackedWidgetBuilder(Entity e, BuildContext context);

/// Widget which observes an entity and rebuilds it's child when the entity has changed.
class EntityObservingWidget extends StatefulWidget {
  /// Function which returns an entity the widget should observe.
  final EntityProvider provider;
  /// Function which is builds widgets child, based on [Entity] and [BuildContext].
  final EntityBackedWidgetBuilder builder;

  const EntityObservingWidget({required this.provider, required this.builder}) : super();

  @override
  State<StatefulWidget> createState() => EntityObservingWidgetState();

}

/// State class for [EntityObservingWidget].
class EntityObservingWidgetState extends State<EntityObservingWidget> implements EntityObserver {
  // holds reference to entity under observation
  Entity? _entity;
  // marks if `setState` was already called
  var _isDirty = false;

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    final manager = EntityManagerProvider.of(context).entityManager;
    _entity = widget.provider(manager);
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    _entity?.addObserver(this);
    return widget.builder(_entity!, context);
  }

  /// Implementation of [EntityObserver]
  @override
  destroyed(Entity e) {
    _update();
  }

  /// Implementation of [EntityObserver]
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
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

typedef Widget EntityNotFoundWidgetBuilder(BuildContext context);

/// Widget which observes an entity and rebuilds it's child when the entity has changed.
class EntityOrNullObservingWidget extends StatefulWidget {
  /// Function which returns an entity the widget should observe.
  final EntityProvider provider;
  /// Function which is builds widgets child, based on [Entity] and [BuildContext].
  final EntityBackedWidgetBuilder builder;
  final EntityNotFoundWidgetBuilder builderNotFound;

  const EntityOrNullObservingWidget({required this.provider, required this.builder, required this.builderNotFound}) : super();

  @override
  State<StatefulWidget> createState() => EntityObservingWidgetState();
}

/// State class for [EntityObservingWidget].
class EntityOrNullObservingWidgetState extends State<EntityOrNullObservingWidget> implements EntityObserver {
  // holds reference to entity under observation
  Entity? _entity;
  // marks if `setState` was already called
  var _isDirty = false;

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    final manager = EntityManagerProvider.of(context).entityManager;
    _entity = widget.provider(manager);
    _entity?.removeObserver(this);
    _entity = widget.provider(manager);
    _entity?.addObserver(this);
    return _entity != null ? widget.builder(_entity!, context) : widget.builderNotFound(context);
  }

  /// Implementation of [EntityObserver]
  @override
  destroyed(Entity e) {
    _update();
  }

  /// Implementation of [EntityObserver]
  @override
  exchanged(Entity e, Component? oldC, Component? newC) {
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

  const GroupObservingWidget({required this.matcher, required this.builder});

  @override
  State<StatefulWidget> createState() => GroupObservingWidgetState();

}

class GroupObservingWidgetState extends State<GroupObservingWidget> implements GroupObserver {
  // holds reference to group under observation
  Group? _group;
  // marks if `setState` was already called
  var _isDirty = false;

  @override
  Widget build(BuildContext context) {
    _isDirty = false;
    var manager = EntityManagerProvider.of(context).entityManager;
    _group?.removeObserver(this);
    _group = manager.groupMatching(widget.matcher);
    _group?.addObserver(this);

    return widget.builder(_group!, context);
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
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