import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'components.dart';
import 'systems.dart';
import 'widgets.dart';

void main() => runApp(buildApp());

Widget buildApp() {
  final em = EntityManager();

  return EntityManagerProvider(
    entityManager: em,
    systems: ReactiveRootSystem(em, [
      CreateProductsSystem(),
      SetupCurrencyConversionSystem(),
      AddItemToShoppingCartSystem(),
      RemoveItemFromShoppingCartSystem(),
      ComputeAmountInSelectedCurrencySystem(),
      ComputePriceLabelSystem(),
      SwitchCurrencySystem(),
      ComputeTotalSumSystem(),
      ComputeTotalSumLabelSystem(),
    ]),
    child: MyApp(),
  );
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return GroupObservingWidget(
      matcher: EntityMatcher(all:[CountComponent, AmountInSelectedCurrencyComponent]),
      builder: (group, context) => MaterialApp(
        title: "Shopping with EntitasFF",
        theme: appTheme,
        home: MyHomePage(),
        routes: <String, WidgetBuilder>{
          CartPage.routeName: (context) => CartPage(),
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: EntityObservingWidget(
            provider: (em) => em.getUniqueEntity<TotalAmountLabelComponent>(),
            builder: (e, context){
              final value = e?.get<TotalAmountLabelComponent>()?.value ?? "0";
              return Text('Total: ($value)');
            },
        ),
        actions: <Widget>[
          // The shopping cart button in the app bar
          GroupObservingWidget(
            matcher: EntityMatcher(all: [ProductNameComponent, CountComponent]),
            builder: (group, context) => CartButton(
              itemCount: group.entities.fold(0, (sum, e) => sum + e.get<CountComponent>().value),
              onPressed: () {
                Navigator.of(context).pushNamed(CartPage.routeName);
              },
            ),
          )
        ],
      ),
      body: ProductGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          EntityManagerProvider.of(context).entityManager.setUnique(SwitchCurrencyComponent());
        },
        tooltip: 'decrement count',
        child: new Icon(Icons.cached),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {

  ProductGrid({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GroupObservingWidget(
      matcher: EntityMatcher(all: [ProductNameComponent, PriceLabelComponent]),
      builder: (group, context) => GridView.count(
        crossAxisCount: 2,
        children: group.entities.map((product) {
          return ProductSquare(
            product: product
          );
        }).toList(),
      ),
    );
  }
}