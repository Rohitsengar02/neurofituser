import 'package:flutter/material.dart';

import '../community/community_page.dart';
import '../trainer/trainers_page.dart';

/// Opens a home tab (live coaches, live community) as its own page from
/// shortcuts elsewhere in the app.
Route<void> livePageRoute(Widget tab) => MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          SafeArea(bottom: false, child: tab),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 6,
            left: 10,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ]),
      ),
    );

Route<void> trainersRoute() => livePageRoute(const TrainersPage());
Route<void> communityRoute() => livePageRoute(const CommunityPage());
