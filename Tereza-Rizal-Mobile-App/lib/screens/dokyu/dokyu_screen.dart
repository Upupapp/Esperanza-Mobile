import 'package:flutter/material.dart';
import '../../models/service_request.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../shared/request_list_screen.dart';

/// Dokyu = "Document Requests" in the Web Admin's terminology (see
/// components/citizen/sidebar.blade.php's nav-item label). Web Admin
/// destination: Admin > Document Requests (currently a single Route::view
/// mock page with no backend — see Section 8, Missing Web Admin Processes).
class DokyuScreen extends StatelessWidget {
  const DokyuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RequestListScreen(
      category: ServiceCategory.dokyu,
      title: 'Dokyu',
      subtitle: 'Request and track municipal documents online.',
      catalog: MockCatalog.documentTypes,
      accent: AppColors.brand600,
      icon: Icons.description_outlined,
    );
  }
}
