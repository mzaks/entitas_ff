import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

void main() => runApp(buildApp());

// Component representing the count state
class CountComponent implements UniqueComponent {
  final int value;

  CountComponent(this.value);
}

// Instantiates an entity manager and returns entity manager provider as the root widget. 
Widget buildApp() {
  final em = EntityManager();
  em.setUnique(CountComponent(0));
  return EntityManagerProvider(
    entityManager: em,
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
                // Text widget represnting the count built by [EntityObservingWidget]
                EntityObservingWidget(
                  provider: (em) => em.getUniqueEntity<CountComponent>(),
                  builder: (e, context) => Text(
                        e.get<CountComponent>().value.toString(),
                        style: Theme.of(context).textTheme.display1,
                      ),
                )
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final entityManager =
                  EntityManagerProvider.of(context).entityManager;
              final count = entityManager.getUnique<CountComponent>().value;
              entityManager.setUnique(CountComponent(count + 1));
            },
            tooltip: 'increment count',
            child: new Icon(Icons.add),
          ),
        ));
  }
}
