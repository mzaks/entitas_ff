import 'dart:ui';
import 'package:entitas_ff/entitas_ff.dart';

class ProductIdComponent implements Component {
  final int value;
  ProductIdComponent(this.value);
}

class ProductNameComponent implements Component {
  final String value;
  ProductNameComponent(this.value);
}

class ColorComponent implements Component {
  final Color value;
  ColorComponent(this.value);
}

class CountComponent implements Component {
  final int value;
  CountComponent(this.value);
}

enum Currency {
  euro, usd
}

class PriceComponent implements Component {
  final Currency currency;
  final double amount;

  PriceComponent(this.currency, this.amount);
}

class SelectedCurrencyComponent implements UniqueComponent {
  final Currency value;

  SelectedCurrencyComponent(this.value);
}

class CurrentConversionRateComponent implements UniqueComponent {
  final double usdToEuro;
  final double euroToUsd;

  CurrentConversionRateComponent(this.usdToEuro, this.euroToUsd);
}

class AmountInSelectedCurrencyComponent implements Component {
  final double value;

  AmountInSelectedCurrencyComponent(this.value);
}

class PriceLabelComponent implements Component {
  final String value;

  PriceLabelComponent(this.value);
}

class TotalAmountComponent implements UniqueComponent {
  final double value;

  TotalAmountComponent(this.value);
}

class TotalAmountLabelComponent implements UniqueComponent {
  final String value;

  TotalAmountLabelComponent(this.value);
}

class AddToShoppingCartComponent implements Component {}
class RemoveFromShoppingCartComponent implements Component {}
class SwitchCurrencyComponent implements UniqueComponent {}