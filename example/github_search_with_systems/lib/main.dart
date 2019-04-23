import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

import 'overlays.dart';
import 'components.dart';
import 'github_search_service.dart';
import 'search_result_widget.dart';
import 'systems.dart';

void main() => runApp(buildApp());

Widget buildApp() {
  final em = EntityManager();
  em.setUnique(SearchStateComponent(SearchState.none));
  GithubService(manager: em);
  return EntityManagerProvider(
    entityManager: em,
    systems: RootSystem(em, [
      TickSystem(),
      ScheduleSearchSystem(),
      ProcessResultsSystem(),
      ProcessErrorsSystem(),
      RemoveOldResultsSystem()
    ]),
    child: MaterialApp(
      title: 'EntitasFF Github Search',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
      ),
      home: SearchScreen(),
    ),
  );
}

class SearchScreen extends StatelessWidget {
  SearchScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    setSearchTerm(String text) {
      final em = EntityManagerProvider.of(context).entityManager;
      em.setUnique(SearchTermComponent(text))
      ..set(TickComponent(em.getUnique<CurrentTickComponent>()?.value ?? 0));
    }
    return Scaffold(
          body: Flex(direction: Axis.vertical, children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(16.0, 44.0, 16.0, 4.0),
              child: TextField(
                autocorrect: false,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search Github...',
                ),
                style: TextStyle(
                  fontSize: 36.0,
                  decoration: TextDecoration.none,
                ),
                onChanged: (text) {
                  setSearchTerm(text);
                },
                onSubmitted: (text){
                  setSearchTerm(text);
                },
              ),
            ),
            EntityObservingWidget(
              provider: (m) => m.getUniqueEntity<SearchStateComponent>(),
              builder: (e, context) {
                final state = e.get<SearchStateComponent>();
                return Expanded(
                  child: overlay(state.value),
                );
              },
            )
            
          ]),
        );
  }
}

Widget overlay(SearchState state) {
  switch(state) {
    case SearchState.none: return SearchIntroWidget();
    case SearchState.empty: return EmptyResultWidget();
    case SearchState.loading: return SearchLoadingWidget();
    case SearchState.error: return SearchErrorWidget();
    case SearchState.done: return SearchResultWidget();
  }
  return Container();
}