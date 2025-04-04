import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
import '../models/comic_model.dart';
import '../models/webnovel_episode.dart';

class WebnovelEpisodeScreen extends StatefulWidget {
  final Comic comic;
  final WebnovelEpisode episode;

  const WebnovelEpisodeScreen({
    Key? key,
    required this.comic,
    required this.episode,
  }) : super(key: key);

  @override
  _WebnovelEpisodeScreenState createState() => _WebnovelEpisodeScreenState();
}

class _WebnovelEpisodeScreenState extends State<WebnovelEpisodeScreen> {
  String _content = "";
  List<String> _paragraphs = [];
  bool _isLoading = true;
  double _fontSize = 16.0;
  bool _isDarkMode = true;
  ScrollController _scrollController = ScrollController();
  double _readProgress = 0.0;
  bool _isTranslating = false;
  bool _isTranslated = false;
  late String _originalTitle;
  late String _translatedTitle;
  List<String> _originalParagraphs = [];
  final translator = GoogleTranslator();
  String _currentLanguage = 'Original';
  // Update your _supportedLanguages map to include Indian languages:
  final Map<String, String> _supportedLanguages = {
    'Original': 'English',  // Keep original first
    'bn': 'Bengali',
    'gu': 'Gujarati',
    'hi': 'Hindi',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'or': 'Odia',
    'ta': 'Tamil',
    'te': 'Telugu',
  };

  // Theme colors
  final Color _darkBackground = Color(0xFF000000);
  final Color _darkText = Color(0xFFE0E0E0);
  final Color _accentColor = Color(0xFFA3D749);
  final Color _secondaryColor = Color(0xFF505050);

  @override
  void initState() {
    super.initState();
    _originalTitle = widget.episode.title;
    _translatedTitle = widget.episode.title;
    _loadDocxContent();
    _scrollController.addListener(_updateReadProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateReadProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateReadProgress() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _readProgress = _scrollController.offset / _scrollController.position.maxScrollExtent;
      });
    }
  }

  Future<void> _loadDocxContent() async {
    try {
      // Download the .docx file
      final response = await http.get(Uri.parse(widget.episode.docxUrl));
      if (response.statusCode == 200) {
        // Decode the .docx file (which is a ZIP archive)
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);

        // Find the document.xml file in the archive
        final documentXml = archive.findFile('word/document.xml');
        if (documentXml != null) {
          // Extract text from the XML content
          final xmlContent = String.fromCharCodes(documentXml.content);

          final extractedText = _extractTextFromXml(xmlContent);

          // Split into paragraphs
          final paragraphs = extractedText.split('\n\n')
              .where((p) => p.trim().isNotEmpty)
              .toList();

          setState(() {
            _content = extractedText;
            _paragraphs = paragraphs;
            _isLoading = false;
          });
        } else {
          setState(() {
            _content = "Error: Could not find document.xml in the .docx file.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _content = "Error: Failed to download .docx file.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _content = "Error: $e";
        _isLoading = false;
      });
    }
  }

  String _extractTextFromXml(String xmlContent) {
    final textBuffer = StringBuffer();

    // Pattern for paragraph breaks
    final paragraphRegex = RegExp(r'<w:p[^>]*>.*?</w:p>', dotAll: true);
    final paragraphs = paragraphRegex.allMatches(xmlContent);

    for (final paragraph in paragraphs) {
      final paragraphText = _extractTextFromParagraph(paragraph.group(0) ?? '');
      if (paragraphText.trim().isNotEmpty) {
        // Clean the text before adding it to the buffer
        final cleanedText = cleanText(paragraphText);
        textBuffer.writeln(cleanedText);
        textBuffer.writeln(); // Add blank line between paragraphs
      }
    }

    return textBuffer.toString().trim();
  }

  String _extractTextFromParagraph(String paragraphXml) {
    final textBuffer = StringBuffer();
    final regex = RegExp(r'<w:t[^>]*>([^<]+)</w:t>');
    final matches = regex.allMatches(paragraphXml);

    for (final match in matches) {
      final text = match.group(1)?.trim() ?? '';
      if (text.isNotEmpty) {
        textBuffer.write(normalizeText(text)); // Normalize text
        textBuffer.write(' '); // Add space between text segments
      }
    }

    return textBuffer.toString().trim();
  }

  String cleanText(String text) {
    // Remove any non-printable characters
    return text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  String normalizeText(String text) {
    // Keep only ASCII printable characters
    return text.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }

  Future<void> _showLanguageDialog() async {
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _darkBackground,
          title: Text(
            'Select Language',
            style: TextStyle(color: _accentColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _supportedLanguages.length,
              itemBuilder: (BuildContext context, int index) {
                final languageCode = _supportedLanguages.keys.elementAt(index);
                final languageName = _supportedLanguages[languageCode];
                return ListTile(
                  title: Text(
                    languageName!,
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context, languageCode);
                  },
                  selected: languageCode == _currentLanguage,
                  selectedTileColor: _accentColor.withOpacity(0.2),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedLanguage != null && selectedLanguage != _currentLanguage) {
      await _translateContent(targetLanguage: selectedLanguage);
    }
  }

  Future<void> _translateContent({required String targetLanguage}) async {
    if (_isTranslating || targetLanguage == 'Original') {
      if (targetLanguage == 'Original' && _isTranslated) {
        // Revert to original text
        setState(() {
          _paragraphs = List.from(_originalParagraphs);
          _isTranslated = false;
          _currentLanguage = 'Original';
        });
      }
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translateTitle = await translator.translate(
        _originalTitle,
        to: targetLanguage,
      );
      setState(() {
        _translatedTitle = translateTitle.toString();
      });

      if(!_isTranslated)
        {
          _originalParagraphs = List.from(_paragraphs);

          // Translate all content at once for better performance
          final fullText = _paragraphs.join('\n\n');
          final translation = await translator.translate(
            fullText,
            to: targetLanguage,
          );

          setState(() {
            _paragraphs = translation.text.split('\n\n');
            _isTranslated = true;
            _currentLanguage = targetLanguage;
          });
        }
      else{

        // Translate all content at once for better performance
        final fullText = _originalParagraphs.join('\n\n');
        final translation = await translator.translate(
          fullText,
          to: targetLanguage,
        );

        setState(() {
          _paragraphs = translation.text.split('\n\n');
          _isTranslated = true;
          _currentLanguage = targetLanguage;
          print(_currentLanguage);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isTranslating
                ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            )
                : Stack(
              children: [
                Icon(
                  Icons.translate,
                  color: _isTranslated ? _accentColor : _accentColor.withOpacity(0.6),
                ),
                if (_isTranslated)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        _supportedLanguages[_currentLanguage]?.substring(0, 2) ?? '',
                        style: TextStyle(
                          color: _darkBackground,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showLanguageDialog,
          ),
          IconButton(
            icon: Icon(Icons.text_increase, color: _accentColor),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize < 24 ? _fontSize + 2 : _fontSize;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.text_decrease, color: _accentColor),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize > 12 ? _fontSize - 2 : _fontSize;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        )
            : Column(
          children: [
            Expanded(
              child: Container(
                color: _darkBackground,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode title and number
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
                          _currentLanguage != 'Original' ? _translatedTitle : _originalTitle,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Chapter title
                      Text(
                        _currentLanguage != 'Original' ? _translatedTitle : _originalTitle,
                        style: TextStyle(
                          color: _darkText,
                          fontSize: _fontSize + 8,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Merriweather',
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Content
                      ..._paragraphs.map((paragraph) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            paragraph,
                            style: TextStyle(
                              color: _darkText.withOpacity(0.9),
                              fontSize: _fontSize,
                              height: 1.6,
                              fontFamily: 'Merriweather',
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom progress bar
            Container(
              height: 3,
              child: LinearProgressIndicator(
                value: _readProgress,
                backgroundColor: _secondaryColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
            ),
            Container(
              color: _darkBackground,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${(_readProgress * 100).toInt()}%",
                    style: TextStyle(
                      color: _secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "Scroll up to begin reading",
                    style: TextStyle(
                      color: _secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: _secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}