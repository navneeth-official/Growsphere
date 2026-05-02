import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'grow_layout.dart';

/// Tools hub sub-pages: green shell, "Tools" inner row, back to hub, bottom nav stays on Tools.
class GrowToolShell extends StatelessWidget {
  const GrowToolShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowLayout(
      innerTitle: l.tabTools,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/tools');
                  }
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l.backToTools),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
