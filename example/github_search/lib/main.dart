import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';

import 'overlays.dart';
import 'components.dart';
import 'github_search_service.dart';
import 'search_result_widget.dart';

void main() => runApp(buildApp());

Widget buildApp() {
  final m = EntityManager();
  m.setUnique(SearchStateComponent(SearchState.none));
  GithubService(manager: m);
  return EntityManagerProvider(
    entityManager: m,
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
                onSubmitted: (text){
                  final em = EntityManagerProvider.of(context).entityManager;
                  em.getUnique<GithubApiComponent>().ref.search(text);
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