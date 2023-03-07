import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:p3pch4t/add_contact.dart';
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return AddContact(
                  initialContact: href,
                );
              },
            ),
          );
        } else {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
