import 'package:entitas_ff/entitas_ff.dart';

import 'github_search_service.dart';

enum SearchState {
  none, empty, loading, error, done
}

class SearchStateComponent implements UniqueComponent {
  final SearchState value;
  SearchStateComponent(this.value);
}

class NameComponent implements Component {
  final String value;
  NameComponent(this.value);
}

class UrlComponent implements Component {
  final String value;
  UrlComponent(this.value);
}

class AvatarUrlComponent implements Component {
  final String value;
  AvatarUrlComponent(this.value);
}

class GithubApiComponent implements UniqueComponent {
  final GithubService ref;
  GithubApiComponent(this.ref);
}