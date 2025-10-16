import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_cloud_provider.dart';
import '../services/offline_queue.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'simulate_offline_share_once') {
          await FirebaseFirestore.instance.disableNetwork();
          try {
            await context.read<LocationCloudProvider>().shareOnce();
          } catch (_) {
          } finally {
            await Future.delayed(const Duration(seconds: 1));
            await FirebaseFirestore.instance.enableNetwork();
          }
        }
        if (v == 'oq_size') {
          debugPrint('[DEV] OQ size: ${OfflineQueue.I.size()}');
          await OfflineQueue.I.flush();
        }
        if (v == 'oq_clear') {
          await OfflineQueue.I.clear();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'simulate_offline_share_once',
          child: Text('Debug: Offline → shareOnce()'),
        ),
        const PopupMenuItem(
          value: 'oq_size',
          child: const Text('Debug: OQ size/flush'),
        ),
        const PopupMenuItem(
          value: 'oq_clear',
          child: const Text('Debug: OQ clear'),
        ),
      ],
    );
  }
}
