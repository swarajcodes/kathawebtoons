import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:kathawebtoons/screens/webnovel_episode_screen.dart';
import '../models/comic_model.dart';
import '../models/episode_model.dart';
import '../models/webnovel_episode.dart';
import '../widgets/comic_header.dart';
import '../widgets/episode_list_tile.dart';
import 'episode_detail_screen.dart';
import 'home_screen.dart';


// Theme colors to match the reader screen
final Color _darkBackground = Color(0xFF000000);
final Color _darkText = Color(0xFFE0E0E0);
final Color _accentColor = Color(0xFFA3D749); // Light green accent
final Color _secondaryColor = Color(0xFF505050); // Gray for secondary elements

class ComicDetailScreen extends StatefulWidget {
  final Comic comic;

  const ComicDetailScreen({Key? key, required this.comic}) : super(key: key);

  @override
  _ComicDetailScreenState createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Episode> _episodes = [];
  List<WebnovelEpisode> _webnovelEpisodes = [];
  bool _isLoadingEpisodes = true;
  bool _isCollapsingHeader = false;

  // Add cached content to avoid repeated fetching
  String? _cachedWebnovelContent;
  bool _isLoadingWebnovelContent = false;

  @override
  void initState() {
    super.initState();
    if (widget.comic.type == 'webnovel') {
      _fetchWebnovelEpisodes();
    } else {
      _fetchEpisodes();
    }

    _scrollController.addListener(() {
      setState(() {
        _isCollapsingHeader = _scrollController.hasClients &&
            _scrollController.offset > 100;
      });
    });
  }

  Future<void> _fetchEpisodes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comics')
          .doc(widget.comic.id)
          .collection('episodes')
          .orderBy('number', descending: false)
          .get();

      final episodes = snapshot.docs
          .map((doc) => Episode.fromFirestore(doc))
          .toList();

      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    } catch (e) {
      print("Error fetching episodes: $e");
      setState(() {
        _isLoadingEpisodes = false;
      });
    }
  }

  Future<void> _fetchWebnovelEpisodes() async {
    try {
      final episodes = await ComicRepository().fetchWebnovelEpisodes(widget.comic.id);
      setState(() {
        _webnovelEpisodes = episodes;
        _isLoadingEpisodes = false;
      });

      // Prefetch first episode content for better performance
      if (episodes.isNotEmpty) {
        _prefetchWebnovelContent(episodes.first.docxUrl);
      }
    } catch (e) {
      print("Error fetching webnovel episodes: $e");
      setState(() {
        _isLoadingEpisodes = false;
      });
    }
  }

  // New method to prefetch content once
  Future<void> _prefetchWebnovelContent(String docxUrl) async {
    if (_isLoadingWebnovelContent || _cachedWebnovelContent != null) return;

    setState(() {
      _isLoadingWebnovelContent = true;
    });

    try {
      final content = await _fetchDocxContent(docxUrl);
      setState(() {
        _cachedWebnovelContent = content;
        _isLoadingWebnovelContent = false;
      });
    } catch (e) {
      print("Error prefetching webnovel content: $e");
      setState(() {
        _isLoadingWebnovelContent = false;
      });
    }
  }

  Future<String> _fetchDocxContent(String docxUrl) async {
    try {
      // Download the .docx file
      final response = await http.get(Uri.parse(docxUrl));
      if (response.statusCode == 200) {
        // Decode the .docx file (which is a ZIP archive)
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        // Find the document.xml file in the archive
        final documentXml = archive.findFile('word/document.xml');
        if (documentXml != null) {
          // Extract text from the XML content
          final xmlContent = String.fromCharCodes(documentXml.content);
          return _extractTextFromXml(xmlContent);
        } else {
          return "Error: Could not find document.xml in the .docx file.";
        }
      } else {
        return "Error: Failed to download .docx file.";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  String _extractTextFromXml(String xmlContent) {
    // Simple XML parsing to extract text
    final textBuffer = StringBuffer();
    final regex = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
    final matches = regex.allMatches(xmlContent);
    for (final match in matches) {
      textBuffer.write(match.group(1));
      textBuffer.write(' ');
    }
    return textBuffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _darkBackground,
        extendBodyBehindAppBar: true,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: _darkBackground,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: _isCollapsingHeader
                      ? Text(
                    "  ${widget.comic.title}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ComicHeader(comic: widget.comic),
                      Positioned(
                        top: 40,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.comic.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.comic.author,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        margin: const EdgeInsets.only(right: 8.0),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          widget.comic.genre.isNotEmpty ? widget.comic.genre[0] : '',
                          style: const TextStyle(
                            color:Colors.lightGreenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (widget.comic.genre.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            widget.comic.genre[1],
                            style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (widget.comic.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(width: 2),
                              Text(
                                'NEW 🌟',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(text: 'Preview'),
                      Tab(text: 'All Episodes'),
                    ],
                    indicatorColor: _accentColor,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildPreviewTab(),
              buildEpisodesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (widget.comic.type == 'webnovel') {
      return buildWebnovelPreview();
    } else {
      return _buildComicPreview();
    }
  }

  Widget _buildComicPreview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_episodes.isNotEmpty &&
              (_episodes.first.previewImage.isNotEmpty ||
                  (_episodes.first.images.isNotEmpty))) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _episodes.first.previewImage.isNotEmpty
                    ? _episodes.first.previewImage
                    : _episodes.first.images.first,
                placeholder: (context, url) => Container(
                  height: 400,
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ] else if (_isLoadingEpisodes) ...[
            Container(
              height: 400,
              color: Colors.grey.shade900,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildWebnovelPreview() {

    if (_isLoadingEpisodes) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
        ),
      );
    }

    if (_webnovelEpisodes.isEmpty) {
      return Center(
        child: Text(
          'No episodes found.',
          style: TextStyle(color: _darkText),
        ),
      );
    }

    // Get the first episode
    final firstEpisode = _webnovelEpisodes.first;

    // Use cached content instead of FutureBuilder for better performance
    if (_isLoadingWebnovelContent && _cachedWebnovelContent == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
        ),
      );
    }

    // If no cached content yet but not loading, trigger prefetch
    if (_cachedWebnovelContent == null && !_isLoadingWebnovelContent) {
      _prefetchWebnovelContent(firstEpisode.docxUrl);
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
        ),
      );
    }

    final content = _cachedWebnovelContent ?? "";

    // Split content into paragraphs for better styling
    final paragraphs = content.split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .take(5)  // Limit to first 5 paragraphs for preview
        .toList();

    return Container(
      color: _darkBackground,
      child: Column(
        children: [
          // Preview header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${firstEpisode.title}",
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Preview",
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Episode title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              firstEpisode.title,
              style: TextStyle(
                color: _darkText,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Merriweather',
                height: 1.3,
              ),
            ),
          ),

          // Episode content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...paragraphs.map((paragraph) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        paragraph,
                        style: TextStyle(
                          color: _darkText.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.6,
                          fontFamily: 'Merriweather',
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  }).toList(),

                  // "Continue reading" button
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebnovelEpisodeScreen(
                                comic: widget.comic,
                                episode: firstEpisode,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Continue Reading",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Preview disclaimer
                  Center(
                    child: Text(
                      "This is a preview of the first episode",
                      style: TextStyle(
                        color: _secondaryColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEpisodesTab() {
    return Column(
      children: [
        SizedBox(height: 20,),
        Expanded(child: widget.comic.type == 'webnovel' ? buildWebnovelEpisodesTab() : buildComicEpisodesTab())
      ],
    );

  }

  Widget buildWebnovelEpisodesTab() {

    if (_isLoadingEpisodes) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
        ),
      );
    }

    if (_webnovelEpisodes.isEmpty) {
      return Center(
        child: Text(
          'Episodes Unavailable.',
          style: TextStyle(color: _darkText),
        ),
      );
    }

    return Container(
      color: _darkBackground,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _webnovelEpisodes.length,
        itemBuilder: (context, index) {
          final episode = _webnovelEpisodes[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebnovelEpisodeScreen(
                    comic: widget.comic,
                    episode: episode,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
              child: Row(
                children: [
                  // Episode number in circle
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(
                      image: CachedNetworkImageProvider(widget.comic.coverImage),
                      fit: BoxFit.fitWidth,
                      height: 70,
                      width: 70,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Episode details
                  Expanded(
                    child:  Text(
                      episode.title,
                      style: TextStyle(
                        color: _darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _accentColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildComicEpisodesTab() {
    if (_isLoadingEpisodes) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
        ),
      );
    }

    if (_episodes.isEmpty) {
      return Center(
        child: Text(
          'Episodes unavailable.',
          style: TextStyle(color: _darkText),
        ),
      );
    }

    // Using the same styled card layout as webnovel episodes
    return Container(
      color: _darkBackground,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          final episode = _episodes[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodeDetailScreen(
                    comic: widget.comic,
                    episode: episode,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
              child: Row(
                children: [
                  // Episode images
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image(
                      image: CachedNetworkImageProvider(episode.previewImage),
                      fit: BoxFit.fitWidth,
                      height: 70,
                      width: 70,
                    ),
                  ),
                  SizedBox(width: 16),
                  // Episode details
                  Expanded(
                    child: Text(
                      episode.title,
                      style: TextStyle(
                        color: _darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: _accentColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: _darkBackground,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}