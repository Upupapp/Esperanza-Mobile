import 'package:flutter/material.dart';
import 'service_request.dart';

/// Barangay-level vs LGU/Municipality-level — derived from an office name.
/// Matches how Philippine LGU offices are actually named: a "Barangay Hall"
/// issues barangay-level documents/assistance; every other office
/// (Treasurer's, Municipal Social Welfare and Development Office, Civil
/// Registrar, Business Permits and Licensing Office, etc.) is a
/// municipal/LGU-level office.
///
/// Only [ServiceCatalogScreen]'s department-grouping step uses this now,
/// against [CatalogItem.office] (real, populated from GET /services). It
/// used to also drive a scope filter/badge on the request list screens,
/// against [ServiceRequest.office] -- removed (production-readiness
/// programme, 2026-09-25) once GET /citizen/requests' own list shape turned
/// out not to include `office` at all, which made that specific usage
/// always compare against an empty string.
enum RequestScope { barangay, lgu }

extension RequestScopeX on RequestScope {
  String get label => switch (this) {
        RequestScope.barangay => 'Barangay',
        RequestScope.lgu => 'LGU / Municipality',
      };
}

RequestScope scopeOfOffice(String office) =>
    office.toLowerCase().contains('barangay') ? RequestScope.barangay : RequestScope.lgu;

enum RequestSort { newest, oldest }

extension RequestSortX on RequestSort {
  String get label => switch (this) {
        RequestSort.newest => 'Newest first',
        RequestSort.oldest => 'Oldest first',
      };
}

/// One immutable snapshot of the active Dokyu/Tulong filter state — search
/// text, request type, status, submitted-date range, and sort order.
/// [RequestListScreen] applies this to its category's requests;
/// [FilterBottomSheet] edits a working copy and returns a new instance
/// rather than mutating in place.
///
/// No Barangay/LGU scope facet anymore -- it used to be derived from
/// [ServiceRequest.office], which GET /citizen/requests' own list shape
/// doesn't return at all (production-readiness programme, 2026-09-25; only
/// the per-request detail fetch does). Dropped along with the office line
/// and scope badge on each list card, rather than filtering by data that's
/// always empty against the real API.
@immutable
class RequestFilters {
  final String search;
  final String? typeName;
  final String? status; // AppStatus.label string, or null for "any"
  final DateTimeRange? dateRange;
  final RequestSort sort;

  const RequestFilters({
    this.search = '',
    this.typeName,
    this.status,
    this.dateRange,
    this.sort = RequestSort.newest,
  });

  bool get isActive => search.trim().isNotEmpty || typeName != null || status != null || dateRange != null;

  /// How many distinct filter facets are active — drives the "Filter (3)"
  /// badge and the active-chip row, not counting sort (sort always has a
  /// value, so it's never "off").
  int get activeCount => [
        search.trim().isNotEmpty,
        typeName != null,
        status != null,
        dateRange != null,
      ].where((f) => f).length;

  RequestFilters copyWith({
    String? search,
    String? typeName,
    bool clearTypeName = false,
    String? status,
    bool clearStatus = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    RequestSort? sort,
  }) {
    return RequestFilters(
      search: search ?? this.search,
      typeName: clearTypeName ? null : (typeName ?? this.typeName),
      status: clearStatus ? null : (status ?? this.status),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      sort: sort ?? this.sort,
    );
  }

  List<ServiceRequest> apply(List<ServiceRequest> requests) {
    var result = requests.where((r) {
      if (search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        final matches = r.typeName.toLowerCase().contains(q) || r.referenceNumber.toLowerCase().contains(q);
        if (!matches) return false;
      }
      if (typeName != null && r.typeName != typeName) return false;
      if (status != null && r.status != status) return false;
      if (dateRange != null) {
        final d = DateTime(r.submittedAt.year, r.submittedAt.month, r.submittedAt.day);
        final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
        final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
        if (d.isBefore(start) || d.isAfter(end)) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) => sort == RequestSort.newest
        ? b.submittedAt.compareTo(a.submittedAt)
        : a.submittedAt.compareTo(b.submittedAt));
    return result;
  }
}
