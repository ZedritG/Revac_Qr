import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:revec_qr/app/router/app_routes.dart';
import 'package:revec_qr/core/constants/users_catalog.dart';
import 'package:revec_qr/features/auth/domain/entities/user_role.dart';
import 'package:revec_qr/features/auth/domain/entities/user_session.dart';
import 'package:revec_qr/features/auth/presentation/controllers/session_controller.dart';
import 'package:revec_qr/features/visits/domain/entities/visit_record.dart';
import 'package:revec_qr/features/visits/presentation/controllers/visit_history_controller.dart';

enum VisitTimeFilter {
  all('Todos'),
  today('Hoy'),
  week('Ultimos 7 dias');

  const VisitTimeFilter(this.label);
  final String label;
}

class VisitHistoryScreen extends ConsumerStatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  ConsumerState<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends ConsumerState<VisitHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  VisitTimeFilter _timeFilter = VisitTimeFilter.all;
  String? _technicianFilter;
  ProviderSubscription<AsyncValue<UserSession?>>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = ref.listenManual<AsyncValue<UserSession?>>(
      sessionControllerProvider,
      _handleSessionUpdates,
    );
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSessionUpdates(
    AsyncValue<UserSession?>? previous,
    AsyncValue<UserSession?> next,
  ) {
    if (!mounted) return;
    if (previous?.value != null && next.value == null && !next.isLoading) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final session = sessionState.valueOrNull;
    final role = session?.role;
    final visitState = ref.watch(visitHistoryProvider);

    if (sessionState.isLoading && session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context, session),
      floatingActionButton: role == UserRole.technician
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.visitScanner),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Registrar visita'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121733), Color(0xFF1B2149), Color(0xFF121522)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: visitState.when(
              data: (visits) => _buildDataView(context, role, visits),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorState(
                error: error,
                onRetry: () =>
                    ref.read(visitHistoryProvider.notifier).refresh(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserSession? session) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Text(
        switch (session?.role) {
          UserRole.supervisor => 'Panel de supervisión',
          UserRole.technician => 'Mis visitas de campo',
          _ => 'Historial de visitas',
        },
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (session != null)
          PopupMenuButton<String>(
            color: theme.colorScheme.surface,
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(sessionControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Cerrar sesion'),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
      ],
      bottom: session == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      session.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDataView(
    BuildContext context,
    UserRole? role,
    List<VisitRecord> visits,
  ) {
    final filtered =
        visits
            .where(_matchesSearch)
            .where(_matchesTime)
            .where((visit) => _matchesTechnician(role, visit))
            .toList()
          ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));

    final technicians = role == UserRole.supervisor
        ? _distinctTechnicians(visits)
        : const <String>[];

    if (role == UserRole.supervisor &&
        technicians.isNotEmpty &&
        _technicianFilter != null &&
        !technicians.contains(_technicianFilter)) {
      _technicianFilter = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildSummaryCards(context, visits, filtered),
        const SizedBox(height: 20),
        _buildSearchBar(context),
        const SizedBox(height: 14),
        _buildFilters(context, technicians, role),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(visitHistoryProvider.notifier).refresh(),
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 90), _EmptyState()],
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      final visit = filtered[index];
                      return _VisitListTile(
                        visit: visit,
                        role: role,
                        onTap: () => _showVisitDetails(context, visit, role),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    List<VisitRecord> visits,
    List<VisitRecord> filtered,
  ) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayCount = visits
        .where(
          (visit) =>
              visit.visitedAt.year == today.year &&
              visit.visitedAt.month == today.month &&
              visit.visitedAt.day == today.day,
        )
        .length;
    final weekCount = visits
        .where((visit) => today.difference(visit.visitedAt).inDays <= 7)
        .length;
    final uniqueSites = visits
        .map(
          (visit) =>
              '${visit.latitude.toStringAsFixed(3)}-${visit.longitude.toStringAsFixed(3)}',
        )
        .toSet()
        .length;

    final items = [
      _SummaryItem(
        title: 'Resultados',
        value: filtered.length.toString(),
        subtitle: 'Coinciden con los filtros',
        icon: Icons.filter_alt_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF4D6BFE), Color(0xFF3B47C5)],
        ),
      ),
      _SummaryItem(
        title: 'Hoy',
        value: todayCount.toString(),
        subtitle: 'Visitas registradas',
        icon: Icons.today_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF66C5F3), Color(0xFF3E90D0)],
        ),
      ),
      _SummaryItem(
        title: 'Ult. 7 dias',
        value: weekCount.toString(),
        subtitle: 'Actividad reciente',
        icon: Icons.calendar_view_week_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFF6AE6C), Color(0xFFE56D52)],
        ),
      ),
      _SummaryItem(
        title: 'Sitios',
        value: uniqueSites.toString(),
        subtitle: 'Ubicaciones unicas',
        icon: Icons.place_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF9B8BFF), Color(0xFF6E5BD6)],
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final cardWidth = isCompact ? 170.0 : 200.0;
        final cardHeight = isCompact ? 156.0 : 180.0;

        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: cardWidth),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: isCompact ? 12 : 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        item.icon,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por equipo, codigo o nota',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded),
              ),
      ),
      style: theme.textTheme.bodyMedium,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    List<String> technicians,
    UserRole? role,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final filter in VisitTimeFilter.values)
            ChoiceChip(
              label: Text(filter.label),
              selected: _timeFilter == filter,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _timeFilter = filter;
                });
              },
            ),
          if (role == UserRole.supervisor && technicians.isNotEmpty)
            DropdownButton<String?>(
              value: _technicianFilter,
              hint: const Text('Tecnico'),
              dropdownColor: theme.colorScheme.surface,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los tecnicos'),
                ),
                ...technicians.map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(_technicianName(id)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _technicianFilter = value;
                });
              },
            ),
          if (_searchController.text.isNotEmpty ||
              _timeFilter != VisitTimeFilter.all ||
              _technicianFilter != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _timeFilter = VisitTimeFilter.all;
                  _technicianFilter = null;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }

  bool _matchesSearch(VisitRecord visit) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return visit.teamName.toLowerCase().contains(normalized) ||
        visit.scannedCode.toLowerCase().contains(normalized) ||
        (visit.note?.toLowerCase().contains(normalized) ?? false);
  }

  bool _matchesTime(VisitRecord visit) {
    final now = DateTime.now();
    switch (_timeFilter) {
      case VisitTimeFilter.all:
        return true;
      case VisitTimeFilter.today:
        return visit.visitedAt.year == now.year &&
            visit.visitedAt.month == now.month &&
            visit.visitedAt.day == now.day;
      case VisitTimeFilter.week:
        return now.difference(visit.visitedAt).inDays <= 7;
    }
  }

  bool _matchesTechnician(UserRole? role, VisitRecord visit) {
    if (role != UserRole.supervisor) {
      return true;
    }
    if (_technicianFilter == null) {
      return true;
    }
    return visit.technicianId == _technicianFilter;
  }

  List<String> _distinctTechnicians(List<VisitRecord> visits) {
    final ids = <String>{};
    for (final visit in visits) {
      ids.add(visit.technicianId);
    }
    return ids.toList()..sort();
  }

  String _technicianName(String technicianId) {
    final match = UsersCatalog.all
        .firstWhere(
          (account) => account.id == technicianId,
          orElse: () => UsersCatalog.technician,
        )
        .displayName;
    return match;
  }

  Future<void> _showVisitDetails(
    BuildContext context,
    VisitRecord visit,
    UserRole? role,
  ) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);
    final hasValidCoordinates = visit.latitude != 0 || visit.longitude != 0;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visit.teamName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.qr_code_rounded,
                label: 'Codigo',
                value: visit.scannedCode,
              ),
              _DetailRow(
                icon: Icons.access_time_rounded,
                label: 'Fecha y hora',
                value: dateFormatter.format(visit.visitedAt),
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Ubicacion',
                value:
                    '${visit.latitude.toStringAsFixed(5)}, ${visit.longitude.toStringAsFixed(5)}',
              ),
              if (visit.note != null && visit.note!.isNotEmpty)
                _DetailRow(
                  icon: Icons.note_outlined,
                  label: 'Nota',
                  value: visit.note!,
                ),
              if (role == UserRole.supervisor)
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Tecnico',
                  value: _technicianName(visit.technicianId),
                ),
              if (hasValidCoordinates) ...[
                const SizedBox(height: 20),
                Text(
                  'Ubicacion en mapa',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      options: MapOptions(
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag |
                              InteractiveFlag.doubleTapZoom,
                        ),
                        initialCenter: LatLng(visit.latitude, visit.longitude),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'com.example.revec_qr',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 42,
                              height: 42,
                              point: LatLng(visit.latitude, visit.longitude),
                              child: Icon(
                                Icons.location_pin,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VisitListTile extends StatelessWidget {
  const _VisitListTile({
    required this.visit,
    required this.role,
    required this.onTap,
  });

  final VisitRecord visit;
  final UserRole? role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.85),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F3A7A), Color(0xFF252B5B)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visit.teamName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (role == UserRole.supervisor)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            label: Text(
                              visit.technicianId,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Codigo: ${visit.scannedCode}', style: subtitleStyle),
                    Text(
                      'Ubicacion: ${visit.latitude.toStringAsFixed(5)}, ${visit.longitude.toStringAsFixed(5)}',
                      style: subtitleStyle,
                    ),
                    if (visit.note != null && visit.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        visit.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateFormatter.format(visit.visitedAt),
                          style: subtitleStyle?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(
          Icons.qr_code_2_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Sin registros',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ajusta los filtros o registra una nueva visita.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 58,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ocurrio un error al cargar los registros.',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
