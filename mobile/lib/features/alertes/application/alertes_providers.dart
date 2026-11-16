import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/alertes_api.dart';
import '../../../domain/alertes.dart';

final alertesProvider = FutureProvider<ListeAlertes>(
  (ref) => ref.watch(alertesApiProvider).alertes(),
  retry: (_, _) => null,
);
