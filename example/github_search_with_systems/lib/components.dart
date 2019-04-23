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

class SearchTermComponent implements UniqueComponent {
  final String value;
  SearchTermComponent(this.value);
}

class SearchResultComponent implements Component {
  final String searchTerm;
  final List<Map<String, Object>> repositories;
  SearchResultComponent(this.repositories, this.searchTerm);
}

class SearchErrorComponent implements Component {
  final dynamic value;
  SearchErrorComponent(this.value);
}

class CurrentTickComponent implements UniqueComponent {
  final int value;
  CurrentTickComponent(this.value);
}

class TickComponent implements Component {
  final int value;
  TickComponent(this.value);
}

class CurrentResultFlagComponent implements UniqueComponent {}