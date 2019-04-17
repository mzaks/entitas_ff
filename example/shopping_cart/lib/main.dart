import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'components.dart';
import 'widgets.dart';

void main() => runApp(buildApp());

Widget buildApp() {
  final em = EntityManager();
  createProducts(em);
  return EntityManagerProvider(
    entityManager: em,
    child: MyApp(),
  );
}

createProducts(EntityManager em) {
  Future.delayed(const Duration(milliseconds: 200), () {
    create(int id, String name, Color color) {
      em.createEntity()
      ..set(ProductIdComponent(id))
      ..set(ProductNameComponent(name))
      ..set(ColorComponent(color));
    }

    create(42, "Sweater", const Color(0xFF536DFE));
    create(1024, "Socks", const Color(0xFFFFD500));
    create(1337, "Shawl", const Color(0xFF1CE8B5));
    create(123, "Jacket", const Color(0xFFFF6C00));
    create(201805, "Hat", const Color(0xFF574DDD));
    create(128, "Hoodie", const Color(0xFFABD0F2));
    create(321, "Tuxedo", const Color(0xFF8DA0FC));
    create(1003, "Shirt", const Color(0xFF1CE8B5));
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanilla',
      theme: appTheme,
      home: MyHomePage(),
      routes: <String, WidgetBuilder>{
        CartPage.routeName: (context) => CartPage(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vanilla'),
        actions: <Widget>[
          // The shopping cart button in the app bar
          GroupObservingWidget(
            matcher: EntityMatcher(all: [ProductNameComponent, CountComponent]),
            builder: (group, context) => CartButton(
                  itemCount: group.entities
                      .fold(0, (sum, e) => sum + e.get<CountComponent>().value),
                  onPressed: () {
                    Navigator.of(context).pushNamed(CartPage.routeName);
                  },
                ),
          )
        ],
      ),
      body: ProductGrid(),
    );
  }
}

class ProductGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GroupObservingWidget(
      matcher: EntityMatcher(all: [ProductNameComponent, ColorComponent]),
      builder: (group, context) => GridView.count(
        crossAxisCount: 2,
        children: group.entities.map((product) => ProductSquare(product: product)).toList(),
      ),
    );
  }
}