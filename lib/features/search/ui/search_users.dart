import 'package:cached_network_image/cached_network_image.dart';
import 'package:typesense/typesense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../services/database.dart';
import '../../../router/routes.dart';

class SearchUsers extends StatefulWidget {
  final userSearchEvent;

  const SearchUsers({
    super.key,
    required this.userSearchEvent,
  });

  @override
  State<SearchUsers> createState() => _SearchUsersState();
}

class _SearchUsersState extends State<SearchUsers> {
  var config;
  var client;

  List users = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        getUsers(users),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    var eventHandler = (args) { getResults(args.value); };
    widget.userSearchEvent.subscribe(eventHandler);

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

  getUsers(users) {
    return Column(
      children: List.from(users.map((user) =>
        ListTile(
          leading: user['document']['profilePic'] != null && user['document']['profilePic'] != ''
              ? Hero(
                  tag: user['document']['profilePic'],
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user['document']['profilePic'],
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
            user['document']['name'],
            style: const TextStyle(
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            user['document']['isOnline']
                ? context.tr('online')
                : context.tr('offline'),
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
            var data = await DatabaseMethods.getUserDetails(user['document']['uid']);

            widget.userSearchEvent.unsubscribeAll();

            Navigator.of(context).pop();
            Navigator.pushNamed(context, Routes.chatScreen, arguments: data.data());
          },
        ),
      )),
    );
  }

  getResults(query) async {
    final searchParameters = {
      'q': query,
      'query_by': 'name',
    };

    final responseHits = await client.collection('users').documents.search(searchParameters);

    setState(() {
      users = responseHits['hits'];
    });
  }
}
