import 'package:flutter/material.dart';

class MangaReaderScreen extends StatelessWidget {
  final List<String> images;

  MangaReaderScreen({required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Image.network(images[index], fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}
