import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:p3pch4t/add_contact.dart';
import 'package:p3pch4t/chatscreen.dart';
import 'package:p3pch4t/classes/user.dart';
import 'package:p3pch4t/objectbox.g.dart';
import 'package:p3pch4t/prefs.dart';
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
        return Container();
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
        } else {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
