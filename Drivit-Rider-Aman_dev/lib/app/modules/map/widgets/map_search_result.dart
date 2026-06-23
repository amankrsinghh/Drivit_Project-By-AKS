
import 'package:flutter/material.dart';
import '../controllers/map_controller.dart';

class MapSearchResults extends StatelessWidget {
  final List<PlaceSuggestion> items;
  final ValueChanged<PlaceSuggestion> onTap;
  final VoidCallback? onCurrentLocationTap;
  final String? currentLocationTitle;
  final String? currentLocationSubtitle;

  const MapSearchResults({
    super.key,
    required this.items,
    required this.onTap,
    this.onCurrentLocationTap,
    this.currentLocationTitle,
    this.currentLocationSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (onCurrentLocationTap != null)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.my_location, color: Colors.orange, size: 20),
              title: Text(
                currentLocationTitle ?? "Current location",
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 1,
              ),
              subtitle: currentLocationSubtitle != null 
                ? Text(
                    currentLocationSubtitle!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
              onTap: onCurrentLocationTap,
            ),
          if (onCurrentLocationTap != null && items.isNotEmpty)
            const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = items[i];
              return ListTile(
                dense: true,
                title: Text(
                  s.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onTap(s),
              );
            },
          ),
        ],
      ),
    );
  }
}