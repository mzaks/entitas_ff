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