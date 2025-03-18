import 'dart:async';
import 'package:flutter/material.dart';
import '../models/comic_model.dart';

class HeroCarousel extends StatefulWidget {
  final List<Comic> heroComics;
  final Function(Comic) onComicTap;

  const HeroCarousel({
    required this.heroComics,
    required this.onComicTap,
  });

  @override
  _HeroCarouselState createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start auto-scrolling
    _startAutoScroll();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentPage < widget.heroComics.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.heroComics.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return HeroComicCard(
                comic: widget.heroComics[index],
                onTap: () => widget.onComicTap(widget.heroComics[index]),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.heroComics.length,
                (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Color(0xFFA3D749)
                    : Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Keep your existing HeroComicCard (just remove the outermost Container's width property)
class HeroComicCard extends StatelessWidget {
  final Comic comic;
  final VoidCallback onTap;

  const HeroComicCard({required this.comic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = comic.isHero && comic.heroLandscapeImage.isNotEmpty
        ? comic.heroLandscapeImage // Use landscape image if available
        : comic.coverImage; // Fallback to portrait image

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                comic.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA3D749),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  "Read Now",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}