import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

void main() {
  test('Map over name', (){
    EntityManager em = EntityManager();
    em.createEntity()..set(Name("Max"))..set(Age(37));

    var nameMap = EntityMap<Name, String>(em, (name) => name.value );

    em.createEntity()..set(Name("Alex"))..set(Age(45));

    expect(nameMap["Max"]?.getOrNull<Age>()?.value, 37);
    expect(nameMap["Alex"]?.getOrNull<Age>()?.value, 45);
  });

  test('Multi Map over age', (){
    EntityManager em = EntityManager();
    em.createEntity()..set(Name("Max"))..set(Age(37));
    em.createEntity()..set(Name("Maxim"))..set(Age(45));

    var ageMap = EntityMultiMap<Age, int>(em, (name) => name.value );

    em.createEntity()..set(Name("Alex"))..set(Age(37));

    expect(ageMap[37].length, 2);
    expect(ageMap[37].map((e) => e.getOrNull<Name>()?.value), containsAll(["Max", "Alex"]));

    expect(ageMap[45].length, 1);
    expect(ageMap[45].map((e) => e.getOrNull<Name>()?.value), containsAll(["Maxim"]));

    for (var e in ageMap[37]) {
      e.set(Age(45));
    }
    expect(ageMap[45].length, 3);
    expect(ageMap[45].map((e) => e.getOrNull<Name>()?.value), containsAll(["Maxim", "Max", "Alex"]));
  });
}