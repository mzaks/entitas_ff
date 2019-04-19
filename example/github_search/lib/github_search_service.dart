import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:entitas_ff/entitas_ff.dart';

import 'components.dart';

class GithubService {
  final String baseUrl;
  final EntityManager manager;
  final HttpClient client;
  final Group results;

  GithubService({
    this.manager,
    HttpClient client,
    this.baseUrl = "https://api.github.com/search/repositories?q=",
  })  : this.client = client ?? new HttpClient(),
      this.results = manager.group(all: [NameComponent, UrlComponent, AvatarUrlComponent]) {
    manager.setUnique(GithubApiComponent(this));
  }

  /// Search Github for repositories using the given term
  search(String term) async {
    if (term.isEmpty && results.isEmpty) {
      manager.setUnique(SearchStateComponent(SearchState.none));
      return;
    }
    if (term.isEmpty) {
      return;
    }
    manager.setUnique(SearchStateComponent(SearchState.loading));
    try {
      final result = await _fetchResults(term);
      manager.setUnique(SearchStateComponent(SearchState.done));

      for (var e in results.entities) {
        e.destroy();
      }
      if (result.isEmpty) {
        manager.setUnique(SearchStateComponent(SearchState.empty));
        return;
      }
      for (var item in result) {
        manager.createEntity()
        ..set(NameComponent(item['full_name'] as String))
        ..set(UrlComponent(item['html_url'] as String))
        ..set(AvatarUrlComponent((item["owner"] as Map<String, Object>)["avatar_url"] as String));
      }
    } catch (eror) {
      print(eror);
      manager.setUnique(SearchStateComponent(SearchState.error));
    }
  }
  

  Future<List<Map<String, Object>>> _fetchResults(String term) async {
    final request = await new HttpClient().getUrl(Uri.parse("$baseUrl$term"));
    final response = await request.close();
    final results = json.decode(await response.transform(utf8.decoder).join());

    return (results['items'] as List).cast<Map<String, Object>>();
  }
}