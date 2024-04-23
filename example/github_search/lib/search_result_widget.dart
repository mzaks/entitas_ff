import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'components.dart';

class SearchResultWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GroupObservingWidget(
      matcher: EntityMatcher(all: [NameComponent, UrlComponent, AvatarUrlComponent]),
      builder: (group, context) {
        var results = group.entities;

        return AnimatedOpacity(
          duration: new Duration(milliseconds: 300),
          opacity: results.isNotEmpty ? 1.0 : 0.0,
          child: new ListView.builder(
            itemCount: results.length ?? 0,
            itemBuilder: (context, index) {
              final item = results[index];
              final name = item.get<NameComponent>().value;
              final url = item.get<UrlComponent>().value;
              final avatarUrl = item.get<AvatarUrlComponent>().value;
              return new InkWell(
                onTap: () => showItem(context, item),
                child: new Container(
                  alignment: FractionalOffset.center,
                  margin: new EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        margin: new EdgeInsets.only(right: 16.0),
                        child: new Hero(
                          tag: name,
                          child: new ClipOval(
                            child: new Image.network(
                              avatarUrl,
                              width: 56.0,
                              height: 56.0,
                            ),
                          ),
                        ),
                      ),
                      new Expanded(
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Container(
                              margin: new EdgeInsets.only(
                                top: 6.0,
                                bottom: 4.0,
                              ),
                              child: new Text(
                                "$name",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: new TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            new Container(
                              child: new Text(
                                "$url",
                                style: new TextStyle(
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }
    );
  }

  void showItem(BuildContext context, Entity e) {
    final avatarUrl = e.get<AvatarUrlComponent>().value;
    final name = e.get<NameComponent>().value;
    Navigator.push(
      context,
      new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new Scaffold(
            resizeToAvoidBottomInset: false,
            body: new GestureDetector(
              key: new Key(avatarUrl),
              onTap: () => Navigator.pop(context),
              child: new SizedBox.expand(
                child: new Hero(
                  tag: name,
                  child: new Image.network(
                    avatarUrl,
                    width: MediaQuery.of(context).size.width,
                    height: 300.0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}