import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/webnovel_episode.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/comic_tile.dart';
import '../widgets/coming_soon_grid.dart';
import '../models/comic_model.dart';
import 'comic_detail_screen.dart';

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

  // New method to fetch webnovel episodes
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
      backgroundColor: Color(0xFF131313),
      body: SafeArea(
        child: FutureBuilder<List<Comic>>(
          future: _comicFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
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
                  // Hero Carousel instead of a single HeroComicCard
                  HeroCarousel(
                    heroComics: heroComics,
                    onComicTap: (comic) => _navigateToDetail(context, comic),
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
                    height: 220, // Set an appropriate height for the horizontal list
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

  void _navigateToDetail(BuildContext context, Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicDetailScreen(comic: comic),
      ),
    );
  }
}