import 'package:cached_network_image/cached_network_image.dart';
import 'package:typesense/typesense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/database.dart';
import '../../../router/routes.dart';

class SearchGroups extends StatefulWidget {
  final groupSearchEvent;

  const SearchGroups({
    super.key,
    required this.groupSearchEvent,
  });

  @override
  State<SearchGroups> createState() => _SearchGroupsState();
}

class _SearchGroupsState extends State<SearchGroups> {
  late final _auth = FirebaseAuth.instance;

  var config;
  var client;

  List groups = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        getGroups(groups),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    var eventHandler = (args) { getResults(args.value); };
    widget.groupSearchEvent.subscribe(eventHandler);

    config = Configuration(
      dotenv.env['TYPESENSE_API_KEY']!,
      nodes: {
        Node(
          Protocol.https,
          dotenv.env['TYPESENSE_HOST']!,
          port: 443,
        ),
      },
      numRetries: 3,
      connectionTimeout: const Duration(seconds: 2),
    );

    client = Client(config);
  }

  getGroups(groups) {
    return Column(
      children: List.from(groups.map((group) =>
        ListTile(
          leading: group['document']['groupPic'] != null && group['document']['groupPic'] != ''
              ? Hero(
                  tag: group['document']['groupPic'],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: group['document']['groupPic'],
                      placeholder: (context, url) =>
                          Image.asset('assets/images/loading.gif'),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error_outline_rounded),
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Image.asset(
                  'assets/images/user.png',
                  height: 50.h,
                  width: 50.w,
                  fit: BoxFit.cover,
                ),
          tileColor: const Color(0xff111B21),
          title: Text(
            group['document']['name'],
            style: const TextStyle(
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            group['document']['users'].length.toString() + ' ' + context.tr('users'),
            style: const TextStyle(
              color: Color.fromARGB(255, 179, 178, 178),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          isThreeLine: true,
          titleAlignment: ListTileTitleAlignment.center,
          enableFeedback: true,
          dense: false,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            height: 1.2.h,
          ),
          onTap: () async {
            var data = await DatabaseMethods.getGroup(group['document']['id']);

            widget.groupSearchEvent.unsubscribeAll();

            Navigator.of(context).pop();
            Navigator.pushNamed(context, Routes.groupScreen, arguments: {
              'id': group['document']['id'],
              'name': data['name'],
              'groupPic': data['groupPic'],
              'users': data['users'],
            });
          },
        ),
      )),
    );
  }

  getResults(query) async {
    final searchParameters = {
      'q': query,
      'query_by': 'name',
      'filter_by': 'users.path:=[`users/' + _auth.currentUser!.uid + '`]',
    };

    final responseHits = await client.collection('groups').documents.search(searchParameters);

    setState(() {
      groups = responseHits['hits'];
    });
  }
}
