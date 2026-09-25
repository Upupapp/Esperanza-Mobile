import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async_state_view.dart';
import '../shared/request_list_screen.dart';

/// Dokyu = "Document Requests" in the Web Admin's terminology (see
/// components/citizen/sidebar.blade.php's nav-item label). Web Admin
/// destination: Admin > Document Requests (currently a single Route::view
/// mock page with no backend — see Section 8, Missing Web Admin Processes).
///
/// Both the catalog and the citizen's own request list now come from the
/// real backend (production-readiness programme, 2026-09-25) rather than
/// [MockCatalog] — see [RequestsService.loadCatalog]/[loadRequests]. The
/// two calls run together because [RequestListScreen] needs both before it
/// can render anything meaningful: the catalog for "New Request", the
/// request list for the Active/Done tabs it watches from [RequestsService].
class DokyuScreen extends StatelessWidget {
  const DokyuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestsService = context.read<RequestsService>();
    return AsyncStateView<List<CatalogItem>>(
      loader: () async {
        await Future.wait([requestsService.loadCatalog(), requestsService.loadRequests()]);
        return requestsService.dokyuCatalog;
      },
      builder: (context, catalog, reload) => RequestListScreen(
        category: ServiceCategory.dokyu,
        title: 'Dokyu',
        subtitle: 'Request and track municipal documents online.',
        catalog: catalog,
        accent: AppColors.brand600,
        icon: Icons.description_outlined,
      ),
    );
  }
}
