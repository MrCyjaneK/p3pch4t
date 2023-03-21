import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:p3pch4t/pages/add_contact.dart';
import 'package:p3pch4t/pages/chat/chatscreen.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/helpers/prefs.dart';
import 'package:url_launcher/url_launcher.dart';

class p3pMd extends StatelessWidget {
  const p3pMd({
    super.key,
    required this.msgTxt,
  });

  final String msgTxt;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: msgTxt,
      selectable: true,
      extensionSet: md.ExtensionSet.gitHubWeb,
      imageBuilder: (uri, title, alt) {
        // Images may lead to leaking of IP address without user interaction.
        if (uri.scheme == "data") {
          return Image.memory(base64Decode(
            uri.toString().substring(
                uri.toString().indexOf(";base64,") + ";base64,".length),
          ));
        }
        return Text("unsupported image format (${uri.scheme})");
      },
      onTapLink: (text, href, title) {
        print("text: $text href: $href title: $title");
        if (href == null) return;
        var uri = Uri.tryParse(href);
        if (uri == null) return;

        if (uri.scheme == "i2p") {
          print('${uri.host}${uri.path}');
          final User? u = userBox
              .query(User_.connstring.equals("${uri.host}${uri.path}"))
              .build()
              .findFirst();
          if (u != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return ChatScreenPage(u: u);
              },
            ));
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return AddContact(
                    initialContact: href,
                  );
                },
              ),
            );
          }
        } else if (uri.scheme == "alert") {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(uri.queryParameters["title"].toString()),
                content: SizedBox(
                    child: SingleChildScrollView(
                  child: p3pMd(
                      msgTxt: Uri.decodeQueryComponent(href.substring(
                          href.indexOf("&body=") + "&body=".length))),
                )),
              );
            },
          );
        } else {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
