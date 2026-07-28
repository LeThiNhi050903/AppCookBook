import 'package:flutter/material.dart';
import '../../../data/models/recipe.dart';

class RecipeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Recipe recipe;
  final double expandedHeight;
  RecipeHeaderDelegate({
    required this.recipe,
    required this.expandedHeight,
  });

  @override
  double get minExtent => kToolbarHeight + 10;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bool collapsed = progress > 0.15;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double currentHeight = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
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
                color: collapsed
                    ? Colors.black26
                    : Colors.transparent,
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
                      Colors.black12,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: statusBarHeight + 12,
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
                      icon: Icons.bookmark_border,
                      onTap: () {
                        // TODO: lưu món
                      },
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
  }) {
    return Material(
      color: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
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