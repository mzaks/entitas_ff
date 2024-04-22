import 'package:entitas_ff/entitas_ff.dart';
import 'components.dart';


class TickSystem extends EntityManagerSystem implements InitSystem, ExecuteSystem {
  @override
  init() {
    entityManager.setUnique(CurrentTickComponent(0));
  }
  @override
  execute() {
    var tick = entityManager.getUnique<CurrentTickComponent>().value + 1;
    entityManager.setUnique(CurrentTickComponent(tick));
  }
}

class ScheduleSearchSystem extends EntityManagerSystem implements ExecuteSystem {
  @override
  execute() {
    var searchTermEntity = entityManager.getUniqueEntityOrNull<SearchTermComponent>();
    if (searchTermEntity == null) return;
    var tick = entityManager.getUnique<CurrentTickComponent>().value;
    var searchTick = searchTermEntity.getOrNull<TickComponent>()?.value ?? 0;
    if (searchTick + 20 < tick) {
      var term = searchTermEntity.get<SearchTermComponent>().value;
      if (term.isEmpty && entityManager.group(all:[NameComponent, UrlComponent, AvatarUrlComponent]).isEmpty) {
        entityManager.setUnique(SearchStateComponent(SearchState.none));
      }
      if (term.isNotEmpty) {
        entityManager.setUnique(SearchStateComponent(SearchState.loading));
        entityManager.getUnique<GithubApiComponent>().ref.search(term);
      }
      searchTermEntity.destroy();
    }
  }
}

class ProcessResultsSystem extends TriggeredSystem {
  @override
  GroupChangeEvent get event => GroupChangeEvent.addedOrUpdated;
  @override
  EntityMatcher get matcher => EntityMatcher(all: [CurrentResultFlagComponent, SearchResultComponent]);

  @override
  executeOnChange() {
    entityManager.group(all: [NameComponent, UrlComponent, AvatarUrlComponent]).destroyAllEntities();
    
    var repositories = entityManager.getUniqueEntity<CurrentResultFlagComponent>().get<SearchResultComponent>().repositories;
    if (repositories.isEmpty) {
      entityManager.setUnique(SearchStateComponent(SearchState.empty));
      return;
    }

    entityManager.setUnique(SearchStateComponent(SearchState.done));

    for (var item in repositories) {
      entityManager.createEntity()
      ..set(NameComponent(item['full_name'] as String))
      ..set(UrlComponent(item['html_url'] as String))
      ..set(AvatarUrlComponent((item["owner"] as Map<String, Object>)["avatar_url"] as String));
    }
  }
}

class ProcessErrorsSystem extends EntityManagerSystem implements InitSystem, ExecuteSystem, CleanupSystem {
  late Group _errors;
  @override
  init() {
    _errors = entityManager.group(all: [SearchErrorComponent]);
  }

  @override
  execute() {
    for (var e in _errors.entities) {
      print(e.getOrNull<SearchErrorComponent>()?.value);
      if (e.has(CurrentResultFlagComponent)) {
        entityManager.setUnique(SearchStateComponent(SearchState.error));
      }
    }
  }

  @override
  cleanup() {
    _errors.destroyAllEntities();
  }
}

class RemoveOldResultsSystem extends EntityManagerSystem implements InitSystem, CleanupSystem {
  late Group _searchResults;

  @override
  init() {
    _searchResults = entityManager.group(all:[SearchResultComponent, TickComponent]);
  }

  @override
  cleanup() {
    if (_searchResults.entities.length < 20) {
      return;
    }
    _searchResults.entities.fold<Entity>(
      _searchResults.entities.first, 
      (e1, e2) => e1.get<TickComponent>().value < e2.get<TickComponent>().value ? e1 : e2
    ).destroy();
  }
}