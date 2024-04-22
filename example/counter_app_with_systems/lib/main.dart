import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

void main() => runApp(buildApp());

class CountComponent extends UniqueComponent {
  final int value;

  CountComponent(this.value);
}

class IncreaseCountComponent extends UniqueComponent {}

class InitCounterSystem extends EntityManagerSystem implements InitSystem {
  @override
  init() {
    entityManager.setUnique(CountComponent(0));
  }
}

class IncreaseCounterSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [IncreaseCountComponent]);

  @override
  executeOnChange() {
    final count = entityManager.getUnique<CountComponent>().value;
    entityManager.setUnique(CountComponent(count + 1));
  }
}

class IncreaseCountPeriodicallySystem extends EntityManagerSystem implements ExecuteSystem {
  var tick = 0;

  @override
  execute() {
    tick++;
    if (tick % 10 == 0) {
      entityManager.setUnique(IncreaseCountComponent());
    }
  }
}

Widget buildApp() {
  final em = EntityManager();
  return EntityManagerProvider(
    entityManager: em,
    systems: RootSystem(
        em, [
      InitCounterSystem(),
      IncreaseCounterSystem(),
      IncreaseCountPeriodicallySystem(),
    ]),
    child: MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'EntitasFF Counter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          appBar: new AppBar(
            title: new Text('EntitasFF Counter'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You have pushed the button this many times:',
                ),
                EntityObservingWidget(
                  provider: (m) => m.getUniqueEntity<CountComponent>(),
                  builder: (e, context) => Text(
                    e.get<CountComponent>().value.toString(),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                )
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
              EntityManagerProvider.of(context).entityManager.setUnique(IncreaseCountComponent()),
            tooltip: 'increment count',
            child: new Icon(Icons.add),
          ),
        ));
  }
}