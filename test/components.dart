import 'package:entitas_ff/entitas_ff.dart';

class Name implements Component {
  final String value;

  Name(this.value);
}

class Age implements Component {
  final int value;

  Age(this.value);
}

class Selected implements UniqueComponent {}

class Score implements UniqueComponent {
  final int value;

  Score(this.value);
}

class Position implements Component {
  final int x;
  final int y;

  Position(this.x, this.y);
}

class Velocity implements Component {
  final int x;
  final int y;

  Velocity(this.x, this.y);
}