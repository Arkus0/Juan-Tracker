import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_template.dart';
import '../services/session_template_service.dart';

final sessionTemplateServiceProvider = Provider<SessionTemplateService>((ref) {
  return SessionTemplateService();
});

final sessionTemplatesProvider =
    FutureProvider<List<SessionTemplate>>((ref) async {
      final service = ref.watch(sessionTemplateServiceProvider);
      return service.loadTemplates();
    });
