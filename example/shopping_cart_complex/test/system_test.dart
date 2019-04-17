import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_cart_complex/components.dart';
import 'package:shopping_cart_complex/systems.dart';

void main() {
  test('Setup currency conversion', (){
    // given
    var em = EntityManager();
    var system = RootSystem(em, [SetupCurrencyConversionSystem()]);
    // when
    system.init();
    // then
    expect(em.getUniqueEntity<CurrentConversionRateComponent>() != null, true);
  });
}