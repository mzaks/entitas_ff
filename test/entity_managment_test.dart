import 'package:entitas_ff/entitas_ff.dart';
import 'package:test/test.dart';
import 'components.dart';

void main() {
  
  test('Create entities', (){
    EntityManager em = EntityManager();
    var e1 = em.createEntity()
      ..set(Name('Max'))
      ..set(Age(37))
      ..set(Position(1, 2));
    var e2 = em.createEntity();
    e2 += Name("Alex");
    e2 += Age(45);
    e2 += Position(3, 3);

    expect(em.entities.length, 2);
    expect(em.entities.contains(e1), true);
    expect(em.entities.contains(e2), true);

    e1.destroy();

    expect(em.entities.length, 1);
    expect(em.entities.contains(e1), false);
    expect(em.entities.contains(e2), true);

    expect(e2.get<Name>().value, "Alex");

    e2 += Name("Sasha");
    expect(e2.get<Name>().value, "Sasha");

    expect(e1.isAlive, false);
    expect(e2.isAlive, true);
  });

  test('Get group', (){
    EntityManager em = EntityManager();
    var e1 = em.createEntity()
      ..set(Name('Max'))
      ..set(Age(37))
      ..set(Position(1, 2));
    var e2 = em.createEntity();
    e2 += Name("Alex");
    e2 += Age(45);

    var people = em.group(all: [Name, Age]);
    var people2 = em.group(any: [Name, Age]);
    var peopleWithoutPosition = em.group(all: [Name, Age], none: [Position]);

    expect(people.isEmpty, false);
    expect(people.entities.contains(e1), true);
    expect(people.entities.contains(e2), true);

    expect(people2.isEmpty, false);
    expect(people2.entities.contains(e1), true);
    expect(people2.entities.contains(e2), true);

    expect(peopleWithoutPosition.isEmpty, false);
    expect(peopleWithoutPosition.entities.contains(e1), false);
    expect(peopleWithoutPosition.entities.contains(e2), true);

    e1 -= Age;

    expect(people.isEmpty, false);
    expect(people.entities.contains(e1), false);
    expect(people.entities.contains(e2), true);

    expect(people2.isEmpty, false);
    expect(people2.entities.contains(e1), true);
    expect(people2.entities.contains(e2), true);
  });

  test('Unique component', (){
    EntityManager em = EntityManager();
    var e1 = em.setUnique(Selected());
    expect(e1.hasT<Selected>(), true);
    
    var e2 = em.createEntity();
    expect(em.setUnique(Selected()), e1);
    em.setUniqueOnEntity(Selected(), e2);
    expect(em.getUniqueEntity<Selected>(), e2);

    var e3 = em.setUnique(Score(25));

    expect(em.getUnique<Score>().value, 25);

    em.removeUnique<Score>();
    expect(em.getUnique<Score>()?.value, null);
    expect(em.getUniqueEntity<Score>(), null);
    expect(e3.isAlive, false);
  });
}