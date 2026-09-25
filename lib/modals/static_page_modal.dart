import 'package:flutter/material.dart';

// Import Third Party Packages
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';

class StaticPageModal extends StatelessWidget {
  final String title;
  final Future<String> content;

  const StaticPageModal({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: SizedBox(width: 0),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Column(
              children: [
                FutureBuilder<String>(
                  future: content,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Html(data: snapshot.data);
                    } else if (snapshot.hasError) {
                      return Text(tr("Something went wrong!"));
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
