import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indian veg / non-veg mark: square with a dot.
class VegMark extends StatelessWidget {
  const VegMark({super.key, required this.isVeg, this.size = 14});

  final bool isVeg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = isVeg ? AppColors.veg : AppColors.nonVeg;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(border: Border.all(color: c, width: 1.4), borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.center,
      child: Container(width: size * 0.45, height: size * 0.45, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    );
  }
}

class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: rating >= 4.2 ? AppColors.veg : const Color(0xFF558B2F),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          const Icon(Icons.star_rounded, color: Colors.white, size: 13),
        ]),
      );
}

/// Emoji on a soft gradient tile: stands in for food photos (fully offline).
class EmojiTile extends StatelessWidget {
  const EmojiTile({super.key, required this.emoji, required this.color, this.size = 72, this.radius = 16});

  final String emoji;
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45)],
          ),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.45)),
      );
}

/// +/- stepper or "ADD" button for a dish.
class QtyButton extends StatelessWidget {
  const QtyButton({super.key, required this.qty, required this.onAdd, required this.onRemove, this.addKey});

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final Key? addKey;

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return OutlinedButton(
        key: addKey,
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.maroon,
          side: const BorderSide(color: AppColors.maroon),
          backgroundColor: Colors.white,
          minimumSize: const Size(84, 36),
        ),
        child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w800)),
      );
    }
    return Container(
      height: 36,
      decoration: BoxDecoration(color: AppColors.maroon, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onRemove,
          icon: const Icon(Icons.remove, color: Colors.white, size: 18),
        ),
        Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ]),
    );
  }
}

/// Real food photo (bundled, offline) with the emoji tile as fallback.
class FoodImage extends StatelessWidget {
  const FoodImage({super.key, required this.photo, required this.emoji, required this.color, this.size = 72, this.radius = 16, this.width});

  final String? photo;
  final String emoji;
  final Color color;
  final double size;
  final double radius;

  /// Optional width when the image should not be square (e.g. headers).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final fallback = EmojiTile(emoji: emoji, color: color, size: size, radius: radius);
    if (photo == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/dishes/$photo',
        width: width ?? size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: ((width ?? size) * 2).round(),
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
