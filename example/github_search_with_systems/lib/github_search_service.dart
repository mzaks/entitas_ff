import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:meta/meta.dart';

import 'components.dart';

class GithubService {
  final String baseUrl;
  final EntityManager _manager;
  final HttpClient _client;
  final EntityMap<SearchResultComponent, String> _searchResultCache;

  GithubService({
    required manager,
    HttpClient? client,
    this.baseUrl = "https://api.github.com/search/repositories?q=",
  }) : this._client = client ?? new HttpClient(),
      this._manager = manager,
      _searchResultCache = EntityMap<SearchResultComponent, String>(manager, (c) => c.searchTerm) {
    _manager.setUnique(GithubApiComponent(this));
  }

  search(String term) async {
    var result = _searchResultCache[term] ?? _manager.createEntity();

    try {
      var repositories = await _fetchResults(term);
      result += SearchResultComponent(repositories, term);
    } catch (error) {
      result += SearchErrorComponent(error);
    }
    _manager.setUniqueOnEntity(CurrentResultFlagComponent(), result);
    var tick = _manager.getUnique<CurrentTickComponent>().value;
    result.set(TickComponent(tick));
  }

  Future<List<Map<String, Object>>> _fetchResults(String term) async {
    final request = await _client.getUrl(Uri.parse("$baseUrl$term"));
    final response = await request.close();
    final results = json.decode(await response.transform(utf8.decoder).join());
    var list = (results['items'] as List);

    return list.cast<Map<String, Object>>();
  }
}