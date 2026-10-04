import 'package:flutter/material.dart';

import '../../../data/repositories/supabase_corporate_scan_project_repository.dart';
import '../../../models/corporate_scan_project.dart';
import 'corporate_scan_project_detail_screen.dart';

class CorporateScanProjectsScreen extends StatefulWidget {
  const CorporateScanProjectsScreen({super.key});

  @override
  State<CorporateScanProjectsScreen> createState() =>
      _CorporateScanProjectsScreenState();
}

class _CorporateScanProjectsScreenState
    extends State<CorporateScanProjectsScreen> {
  final CorporateScanProjectRepository _repository =
      CorporateScanProjectRepository();

  late Future<List<CorporateScanProjectOverview>> _future;
  String _query = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchProjectOverviews();
  }

  void _reload() {
    setState(() {
      _future = _repository.fetchProjectOverviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: SafeArea(
        child: FutureBuilder<List<CorporateScanProjectOverview>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }

            final projects = snapshot.data ?? const [];
            final filtered = _filter(projects);

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: _Header(projects: projects, onRefresh: _reload),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: _Toolbar(
                        query: _query,
                        statusFilter: _statusFilter,
                        onQueryChanged: (value) {
                          setState(() => _query = value);
                        },
                        onStatusChanged: (value) {
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 430,
                              mainAxisExtent: 244,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final overview = filtered[index];
                          return _ProjectCard(
                            overview: overview,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CorporateScanProjectDetailScreen(
                                        overview: overview,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<CorporateScanProjectOverview> _filter(
    List<CorporateScanProjectOverview> projects,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();
    return projects.where((overview) {
      final project = overview.project;
      final matchesStatus =
          _statusFilter == 'all' || project.status == _statusFilter;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          project.companyName.toLowerCase().contains(normalizedQuery) ||
          (project.factoryName ?? '').toLowerCase().contains(normalizedQuery) ||
          (project.location ?? '').toLowerCase().contains(normalizedQuery) ||
          (project.deviceId ?? '').toLowerCase().contains(normalizedQuery);
      return matchesStatus && matchesQuery;
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.projects, required this.onRefresh});

  final List<CorporateScanProjectOverview> projects;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final totalEmployees = projects.fold<int>(
      0,
      (sum, item) => sum + item.stats.importedEmployees,
    );
    final completedScans = projects.fold<int>(
      0,
      (sum, item) => sum + item.stats.completedScans,
    );
    final activeProjects = projects
        .where(
          (item) =>
              item.project.status == 'active' ||
              item.project.status == 'paused',
        )
        .length;
    final completion = totalEmployees == 0
        ? 0
        : ((completedScans / totalEmployees) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Kurumsal Taramalar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Fabrika tarama projelerini, çalışan ilerlemesini ve operasyon durumunu takip edin.',
                    style: TextStyle(color: Color(0xFF66736F)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Yenile',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: 'Proje',
              value: projects.length.toString(),
              icon: Icons.business,
            ),
            _MetricTile(
              label: 'Aktif süreç',
              value: activeProjects.toString(),
              icon: Icons.sensors,
            ),
            _MetricTile(
              label: 'Çalışan',
              value: totalEmployees.toString(),
              icon: Icons.groups,
            ),
            _MetricTile(
              label: 'Tamamlanma',
              value: '%$completion',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E9E6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: const TextStyle(color: Color(0xFF66736F))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.statusFilter,
    required this.onQueryChanged,
    required this.onStatusChanged,
  });

  final String query;
  final String statusFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Firma, fabrika, lokasyon veya cihaz ara',
              prefixIcon: const Icon(Icons.search),
              helperText: query.isEmpty ? null : 'Filtre: $query',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE3E9E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE3E9E6)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE3E9E6)),
            ),
            child: DropdownButton<String>(
              value: statusFilter,
              onChanged: (value) {
                if (value != null) onStatusChanged(value);
              },
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tüm durumlar')),
                DropdownMenuItem(value: 'preparing', child: Text('Hazırlıkta')),
                DropdownMenuItem(value: 'active', child: Text('Aktif')),
                DropdownMenuItem(value: 'paused', child: Text('Duraklatıldı')),
                DropdownMenuItem(value: 'completed', child: Text('Tamamlandı')),
                DropdownMenuItem(value: 'closed', child: Text('Kapandı')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.overview, required this.onTap});

  final CorporateScanProjectOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final project = overview.project;
    final stats = overview.stats;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE3E9E6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(project: project),
                ],
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.place_outlined,
                value: project.location ?? 'Lokasyon girilmedi',
              ),
              _InfoLine(
                icon: Icons.memory_outlined,
                value: project.deviceId ?? 'Cihaz atanmamış',
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: stats.completionRate,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8EEEB),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF0F766E)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TinyMetric(
                    label: 'Çalışan',
                    value: stats.importedEmployees.toString(),
                  ),
                  _TinyMetric(
                    label: 'Taranan',
                    value: stats.completedScans.toString(),
                  ),
                  _TinyMetric(
                    label: 'Bekleyen',
                    value: stats.pendingScans.toString(),
                  ),
                  _TinyMetric(
                    label: 'Hata',
                    value: stats.failedScans.toString(),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stats.lastScanAt == null
                          ? 'Henüz tarama yok'
                          : 'Son tarama: ${_formatDateTime(stats.lastScanAt!)}',
                      style: const TextStyle(color: Color(0xFF66736F)),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF66736F)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.project});

  final CorporateScanProject project;

  @override
  Widget build(BuildContext context) {
    final color = switch (project.status) {
      'active' => const Color(0xFF0F766E),
      'paused' => const Color(0xFFB7791F),
      'completed' => const Color(0xFF2563EB),
      'closed' => const Color(0xFF475569),
      _ => const Color(0xFF66736F),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        project.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF66736F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF66736F)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF66736F)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.domain_disabled_outlined,
              size: 42,
              color: Color(0xFF66736F),
            ),
            SizedBox(height: 12),
            Text(
              'Kurumsal tarama projesi yok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Supabase üzerinde bir proje oluşturulduğunda burada kart olarak görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF66736F)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Color(0xFFB42318)),
            const SizedBox(height: 12),
            const Text(
              'Kurumsal taramalar yüklenemedi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF66736F)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year} ${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
