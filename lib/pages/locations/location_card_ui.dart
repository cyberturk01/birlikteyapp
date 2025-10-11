// lib/pages/locations/location_card_ui.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/location_cloud_provider.dart';
import '../locations/locations_page.dart';

class LocationCard extends StatelessWidget {
  final String familyId;
  const LocationCard({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final loc = context.watch<LocationCloudProvider>();
    final isOn = loc.isSharing;

    return // LocationCard minimal
    Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationsPage(familyId: familyId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.location_on, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.familyMap,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      t.shareLoc,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        // color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 4),
              // SizedBox(
              //   width: 16,
              //   height: 16,
              //   child: DecoratedBox(
              //     decoration: BoxDecoration(
              //       color: isOn ? Colors.green : Colors.grey,
              //       shape: BoxShape.circle,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 45) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }
}
