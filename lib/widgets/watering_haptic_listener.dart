import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/grow_session.dart';
import '../providers/providers.dart';

/// While any garden crop’s sprinkler valve is on, fires periodic haptics (device permitting).
class WateringHapticListener extends ConsumerStatefulWidget {
  const WateringHapticListener({super.key});

  @override
  ConsumerState<WateringHapticListener> createState() => _WateringHapticListenerState();
}

class _WateringHapticListenerState extends ConsumerState<WateringHapticListener> {
  Timer? _timer;

  void _evaluate() {
    final storage = ref.read(growStorageProvider);
    final list = ref.read(gardenListProvider);
    final any = list.any((s) => storage.sprinklerOnFor(s.gardenInstanceId));
    if (any) {
      if (_timer == null || !_timer!.isActive) {
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 2), (_) {
          HapticFeedback.mediumImpact();
        });
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _evaluate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(localDataRevisionProvider, (_, __) => _evaluate());
    ref.listen<List<GrowSession>>(gardenListProvider, (_, __) => _evaluate());
    ref.watch(localDataRevisionProvider);
    ref.watch(gardenListProvider);
    return const SizedBox.shrink();
  }
}
