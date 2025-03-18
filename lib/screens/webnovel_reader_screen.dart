import 'package:flutter/material.dart';

class WebnovelReaderScreen extends StatefulWidget {
  final String content; // Text content of the episode
  final String title; // Episode title

  const WebnovelReaderScreen({
    Key? key,
    required this.content,
    required this.title,
  }) : super(key: key);

  @override
  _WebnovelReaderScreenState createState() => _WebnovelReaderScreenState();
}

class _WebnovelReaderScreenState extends State<WebnovelReaderScreen> {
  final PageController _pageController = PageController();
  List<String> _pages = []; // List of pages (text chunks)
  int _currentPage = 0; // Current page index

  @override
  void initState() {
    super.initState();
    _splitContentIntoPages();
  }

  // Split the content into pages based on a fixed number of characters
  void _splitContentIntoPages() {
    const charsPerPage = 1500; // Adjust this value based on your UI
    for (int i = 0; i < widget.content.length; i += charsPerPage) {
      final end = (i + charsPerPage < widget.content.length) ? i + charsPerPage : widget.content.length;
      _pages.add(widget.content.substring(i, end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // TODO: Add settings for text size, font, and theme
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              _pages[index],
              style: TextStyle(fontSize: 16), // Default text size
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            Text("Page ${_currentPage + 1} of ${_pages.length}"),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}