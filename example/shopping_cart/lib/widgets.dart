import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'components.dart';

/// The top-level theme of the whole app.
final appTheme = ThemeData(
    primaryColor: Colors.white
);

class ProductSquare extends StatelessWidget {
  final Entity product;

  ProductSquare({
    required this.product
  }) : super();

  @override
  Widget build(BuildContext context) {
    final color = product.get<ColorComponent>().value;
    final name = product.get<ProductNameComponent>().value;
    return Material(
      color: color,
      child: InkWell(
        onTap: (){
          final prevCount = product.getOrNull<CountComponent>()?.value ?? 0;
          // ignore: unnecessary_statements
          product + CountComponent(prevCount + 1);
        },
        child: Center(
            child: Text(
              name,
              style: TextStyle(
                  color: isDark(color) ? Colors.white : Colors.black),
            )),
      ),
    );
  }
}

class CartButton extends StatefulWidget {
  /// The function to call when the icon button is pressed.
  final VoidCallback onPressed;

  /// Number of items in the basket. When this is `0`, no badge will be shown.
  final int itemCount;

  final Color badgeColor;

  final Color badgeTextColor;

  CartButton({
    required this.itemCount,
    required this.onPressed,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  })  : assert(itemCount >= 0),
        super();

  @override
  CartButtonState createState() {
    return CartButtonState();
  }
}

class CartButtonState extends State<CartButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final Tween<Offset> _badgePositionTween = Tween(
    begin: const Offset(-0.5, 0.9),
    end: const Offset(0.0, 0.0),
  );

  @override
  Widget build(BuildContext context) {

    return IconButton(
        icon: Stack(
          clipBehavior: Clip.none, children: [
            Icon(Icons.shopping_cart),
            Positioned(
              top: -8.0,
              right: -3.0,
              child: SlideTransition(
                position: _badgePositionTween.animate(_animation),
                child: Material(
                    type: MaterialType.circle,
                    elevation: 2.0,
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        widget.itemCount.toString(),
                        style: TextStyle(
                          fontSize: 13.0,
                          color: widget.badgeTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              ),
            ),
          ],
        ),
        onPressed: widget.onPressed);
  }

  @override
  void didUpdateWidget(CartButton oldWidget) {
    if (widget.itemCount != oldWidget.itemCount) {
      _animationController.reset();
      _animationController.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut);
    _animationController.forward();
  }
}

class CartPage extends StatelessWidget {
  static const routeName = "/cart";

  @override
  Widget build(BuildContext context) {
    final group = EntityManagerProvider.of(context).entityManager.group(all: [ProductNameComponent, ColorComponent, CountComponent]);
    var sortedEntries = List.of(group.entities);
    sortedEntries.sort((a, b) => b.get<CountComponent>().value.compareTo(a.get<CountComponent>().value));
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Cart"),
      ),
      body: group.isEmpty
          ? Center(
          child: Text('Empty', style: Theme.of(context).textTheme.displayMedium))
          : ListView(
          children:
          sortedEntries.map((item) => ItemTile(item: item)).toList()),
    );
  }
}

class ItemTile extends StatelessWidget {
  ItemTile({required this.item});
  final Entity item;

  @override
  Widget build(BuildContext context) {
    final color = item.get<ColorComponent>().value;
    final name = item.get<ProductNameComponent>().value;
    final count = item.get<CountComponent>().value;
    final textStyle = TextStyle(
        color: isDark(color) ? Colors.white : Colors.black);

    return Container(
      color: color,
      child: ListTile(
        title: Text(
          name,
          style: textStyle,
        ),
        trailing: CircleAvatar(
            backgroundColor: const Color(0x33FFFFFF),
            child: Text(count.toString(), style: textStyle)),
      ),
    );
  }
}

/// See https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
bool isDark(Color color) {
  return (0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) < 150;
}