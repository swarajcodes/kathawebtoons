import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../models/webnovel_episode.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/comic_tile.dart';
import '../widgets/coming_soon_grid.dart';
import '../models/comic_model.dart';
import 'comic_detail_screen.dart';
import 'katha_screen.dart'; // Make sure to import your KathaScreen

class ComicRepository {
  static final ComicRepository _instance = ComicRepository._internal();
  factory ComicRepository() => _instance;

  ComicRepository._internal();

  List<Comic> _comics = [];
  bool _isFetched = false;

  Future<List<Comic>> fetchComics() async {
    if (_isFetched) return _comics;

    try {
      final snapshot = await FirebaseFirestore.instance.collection('comics').get();
      _comics = snapshot.docs.map((doc) => Comic.fromFirestore(doc)).toList();
      _isFetched = true;
    } catch (e) {
      print("Error fetching comics: $e");
    }
    return _comics;
  }

  Future<List<WebnovelEpisode>> fetchWebnovelEpisodes(String comicId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(comicId)
          .collection('webnovelEpisodes')
          .orderBy('number', descending: false)
          .get();

      return snapshot.docs.map((doc) => WebnovelEpisode.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching webnovel episodes: $e");
      return [];
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Comic>> _comicFuture;

  @override
  void initState() {
    super.initState();
    _comicFuture = ComicRepository().fetchComics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SafeArea(
        child: FutureBuilder<List<Comic>>(
          future: _comicFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildShimmerLoading();
            }
            final comics = snapshot.data!;

            // Get all hero comics
            final heroComics = comics.where((comic) => comic.isHero).toList();

            // Fallback if no hero comics found
            if (heroComics.isEmpty) {
              heroComics.add(Comic(
                id: 'default',
                title: 'No Hero Comic',
                author: 'Unknown',
                coverImage: 'https://via.placeholder.com/150',
                heroLandscapeImage: 'https://via.placeholder.com/150',
                genre: [],
                isHero: true,
              ));
            }

            // Get all recommended comics
            final recommendedComics = comics.where((comic) => comic.isRecommended).toList();

            // Get all webnovels
            final webnovels = comics.where((comic) => comic.type == 'webnovel').toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Carousel
                  HeroCarousel(
                    heroComics: heroComics,
                    onComicTap: (comic) => _navigateToDetail(context, comic),
                  ),
                  SizedBox(height: 20),

                  // Bloodhound Baserville Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Bloodhound Baserville',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => KathaScreen()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Color(0xFFA3D749),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bloodhound Baserville',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Explore the mystical katha stories',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'View',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Recommended Comics Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'For You ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Grid of recommended comics
                  Container(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recommendedComics.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: 16),
                          child: ComicTile(
                            comic: recommendedComics[index],
                            onTap: () => _navigateToDetail(context, recommendedComics[index]),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 20),

                  // Webnovels Section
                  if (webnovels.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Explore Webnovels 📚',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: webnovels.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: 16),
                            child: ComicTile(
                              comic: webnovels[index],
                              onTap: () => _navigateToDetail(context, webnovels[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Coming Soon Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Coming Soon 🥳',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ComingSoonGrid(comics: comics),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Shimmer loading placeholder widgets
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero carousel shimmer
          _buildHeroShimmer(),
          SizedBox(height: 20),

          // Bloodhound Baserville shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Bloodhound Baserville',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: Color(0xFF333333),
            highlightColor: Color(0xFF444444),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20),

          // For You section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'For You ✨',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildHorizontalListShimmer(),

          SizedBox(height: 20),

          // Webnovels section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Explore Webnovels 📚',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildHorizontalListShimmer(),

          SizedBox(height: 20),

          // Coming Soon section shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Coming Soon 🥳',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          _buildGridShimmer(),
        ],
      ),
    );
  }

  Widget _buildHeroShimmer() {
    return Shimmer.fromColors(
      baseColor: Color(0xFF333333),
      highlightColor: Color(0xFF444444),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHorizontalListShimmer() {
    return Container(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Color(0xFF333333),
              highlightColor: Color(0xFF444444),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Color(0xFF333333),
            highlightColor: Color(0xFF444444),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicDetailScreen(comic: comic),
      ),
    );
  }
}