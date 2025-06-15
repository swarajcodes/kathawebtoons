import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DocumentViewer extends StatefulWidget {
  final List<String> imageUrls;
  final TransformationController transformationController;
  final ScrollController scrollController;
  final String heroTagPrefix;

  const DocumentViewer({
    Key? key,
    required this.imageUrls,
    required this.transformationController,
    required this.scrollController,
    required this.heroTagPrefix,
  }) : super(key: key);

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Matrix4> _animation;

  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _doubleTapScale = 2.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Matrix4Tween().animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    final Matrix4 currentMatrix = widget.transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    Matrix4 targetMatrix;

    if (currentScale > _minScale + 0.1) {
      // Zoom out to original scale
      targetMatrix = Matrix4.identity();
    } else {
      // Zoom in to double tap scale, centered on tap position
      final Size size = renderBox.size;
      final Offset focalPoint = localPosition;

      targetMatrix = Matrix4.identity()
        ..translate(focalPoint.dx, focalPoint.dy)
        ..scale(_doubleTapScale)
        ..translate(-focalPoint.dx, -focalPoint.dy);

      // Ensure the zoomed content stays within bounds
      targetMatrix = _constrainMatrix(targetMatrix, size);
    }

    _animateToMatrix(targetMatrix);
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    final Matrix4 currentMatrix = widget.transformationController.value;

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.reset();
    _animationController.forward();

    _animation.addListener(() {
      widget.transformationController.value = _animation.value;
    });
  }

  Matrix4 _constrainMatrix(Matrix4 matrix, Size size) {
    final double scale = matrix.getMaxScaleOnAxis();

    // Convert Vector3 to Offset properly
    final translationVector = matrix.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);

    // Calculate bounds for the entire document
    final double scaledWidth = size.width * scale;
    final double scaledHeight = size.height * scale;

    double constrainedX = translation.dx;
    double constrainedY = translation.dy;

    // Constrain horizontal movement
    if (scaledWidth > size.width) {
      final double maxX = 0.0;
      final double minX = size.width - scaledWidth;
      constrainedX = constrainedX.clamp(minX, maxX);
    } else {
      constrainedX = (size.width - scaledWidth) / 2;
    }

    // Constrain vertical movement
    if (scaledHeight > size.height) {
      final double maxY = 0.0;
      final double minY = size.height - scaledHeight;
      constrainedY = constrainedY.clamp(minY, maxY);
    } else {
      constrainedY = (size.height - scaledHeight) / 2;
    }

    return Matrix4.identity()
      ..translate(constrainedX, constrainedY)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: widget.transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          constrained: true,
          boundaryMargin: const EdgeInsets.all(20.0),
          // Add these properties to reduce delay
          panEnabled: true,
          scaleEnabled: true,
          // This helps with gesture recognition
          clipBehavior: Clip.none,
          onInteractionStart: (ScaleStartDetails details) {
            // Immediately respond to gesture start
            if (details.pointerCount >= 2) {
              // Two fingers detected - prepare for zoom
            }
          },
          onInteractionUpdate: (ScaleUpdateDetails details) {
            // More responsive updates
          },
          onInteractionEnd: (ScaleEndDetails details) {
            // Bounce back to bounds if needed
            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final Matrix4 currentMatrix = widget.transformationController.value;
              final Matrix4 constrainedMatrix = _constrainMatrix(currentMatrix, renderBox.size);

              if (currentMatrix != constrainedMatrix) {
                _animateToMatrix(constrainedMatrix);
              }
            }
          },
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: widget.imageUrls.asMap().entries.map((entry) {
                int index = entry.key;
                String imageUrl = entry.value;

                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  child: Hero(
                    tag: "${widget.heroTagPrefix}_$index",
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.fitWidth, // Fit to screen width, maintain aspect ratio
                      placeholder: (context, url) => Container(
                        height: 400,
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 400,
                        color: Colors.grey.shade900,
                        child: const Center(
                          child: Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
