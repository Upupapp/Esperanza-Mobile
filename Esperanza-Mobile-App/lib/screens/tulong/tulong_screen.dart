import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async_state_view.dart';
import '../shared/request_list_screen.dart';

/// Tulong = "Assistance Requests" (see components/citizen/sidebar.blade.php).
/// Web Admin destination: Admin > Assistance Requests (currently a single
/// Route::view mock page — see Section 8, Missing Web Admin Processes).
///
/// See [DokyuScreen]'s doc comment — same real-backend loading pattern,
/// same reason both [RequestsService.loadCatalog] and [loadRequests] run
/// together here.
class TulongScreen extends StatelessWidget {
  const TulongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestsService = context.read<RequestsService>();
    return AsyncStateView<List<CatalogItem>>(
      loader: () async {
        await Future.wait([requestsService.loadCatalog(), requestsService.loadRequests()]);
        return requestsService.tulongCatalog;
      },
      builder: (context, catalog, reload) => RequestListScreen(
        category: ServiceCategory.tulong,
        title: 'Tulong',
        subtitle: 'Submit and follow up assistance program requests.',
        catalog: catalog,
        accent: AppColors.purple700,
        icon: Icons.volunteer_activism_outlined,
      ),
    );
  }
}
