import 'package:flutter/material.dart';
import '../../../data/models/recipe.dart';
import '../../core/services/firebase_service.dart';

class RecipeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Recipe recipe;
  final double expandedHeight;
  static final FirebaseService _firebaseService = FirebaseService();
  RecipeHeaderDelegate({
    required this.recipe,
    required this.expandedHeight,
  });

  @override
  double get minExtent => 110;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final currentHeight = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    return SizedBox(
      height: currentHeight,
      child: Container(
        color: Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              top: statusBarHeight,
              child: Hero(
                tag: recipe.id,
                child: _buildHeaderImage(),
              ),
            ),
            Positioned.fill(
              top: statusBarHeight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: Colors.black26,
              ),
            ),
            Positioned.fill(
              top: statusBarHeight,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black45,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: statusBarHeight + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _circleButton(
                    icon: Icons.push_pin_outlined,
                    onTap: () {
    
                    },
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 44,
                    child: StreamBuilder<bool>(
                      stream: _firebaseService.streamIsRecipeSaved(recipe.id),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;
                        return TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 220),
                          tween: Tween(begin: 0.9, end: 1),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: _circleButton(
                            icon: isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            iconColor:
                                isSaved ? Colors.amber : Colors.white,
                            onTap: () async {
                              await _firebaseService.toggleSaveRecipe(
                                recipe.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleButton(
                    icon: Icons.more_vert,
                    onTap: () => _showMoreMenu(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    if (recipe.thumbnail.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 70,
            color: Colors.grey,
          ),
        ),
      );
    }
    return Image.network(
      recipe.thumbnail,
      fit: BoxFit.cover,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 70,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 250,
              ),
              transitionBuilder:
                  (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: iconColor,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Báo cáo'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(
    covariant RecipeHeaderDelegate oldDelegate,
  ) {
    return recipe.id != oldDelegate.recipe.id ||
        expandedHeight != oldDelegate.expandedHeight;
  }
}