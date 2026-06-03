import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpertControlPanelScreen extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback? onNewMeasurementTap;
  final VoidCallback? onMeasurementHistoryTap;

  const ExpertControlPanelScreen({
    super.key,
    required this.currentUser,
    this.onNewMeasurementTap,
    this.onMeasurementHistoryTap,
  });

  @override
  State<ExpertControlPanelScreen> createState() =>
      _ExpertControlPanelScreenState();
}

class _ExpertControlPanelScreenState extends State<ExpertControlPanelScreen> {
  SupabaseClient get _client => Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  int _todayCount = 0;
  int _weeklyCount = 0;
  int _monthlyCount = 0;
  int _allTimeCount = 0;

  List<_DailyMeasurementCount> _lastSevenDays = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final expertUserId = widget.currentUser.userId;

      if (expertUserId == null) {
        throw Exception('Uzman kullanıcı ID bulunamadı.');
      }

      final now = DateTime.now();

      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 6));
      final monthStart = DateTime(now.year, now.month, 1);

      final response = await _client
          .from('measurement_sessions')
          .select('id, session_date, created_at, expert_user_id')
          .eq('expert_user_id', expertUserId)
          .order('session_date', ascending: false);

      final rows = response as List<dynamic>;

      final sessionDates = rows.map((item) {
        final map = Map<String, dynamic>.from(item as Map);

        final sessionDateRaw = map['session_date'];
        final createdAtRaw = map['created_at'];

        return _parseDate(sessionDateRaw) ?? _parseDate(createdAtRaw);
      }).whereType<DateTime>().toList();

      final todayCount = sessionDates.where((date) {
        return !_dateOnly(date).isBefore(todayStart);
      }).length;

      final weeklyCount = sessionDates.where((date) {
        return !_dateOnly(date).isBefore(weekStart);
      }).length;

      final monthlyCount = sessionDates.where((date) {
        return !_dateOnly(date).isBefore(monthStart);
      }).length;

      final lastSevenDays = List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final count = sessionDates.where((item) {
          return _isSameDay(item, date);
        }).length;

        return _DailyMeasurementCount(
          date: date,
          count: count,
        );
      });

      if (!mounted) return;

      setState(() {
        _todayCount = todayCount;
        _weeklyCount = weeklyCount;
        _monthlyCount = monthlyCount;
        _allTimeCount = rows.length;
        _lastSevenDays = lastSevenDays;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Kontrol paneli verileri yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildStatsGrid(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildWeeklyChartCard(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildQuickActionsCard(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal,
            child: Icon(
              Icons.dashboard_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldiniz, ${widget.currentUser.displayName}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bugünkü ölçüm akışınızı, haftalık performansı ve hızlı işlemleri buradan takip edebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadStats,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Bugünkü Ölçüm',
          value: _todayCount.toString(),
          icon: Icons.today_outlined,
          helper: 'Bugün alınan ölçüm',
        ),
        _buildStatCard(
          title: 'Haftalık Ölçüm',
          value: _weeklyCount.toString(),
          icon: Icons.date_range_outlined,
          helper: 'Son 7 gün',
        ),
        _buildStatCard(
          title: 'Aylık Ölçüm',
          value: _monthlyCount.toString(),
          icon: Icons.calendar_month_outlined,
          helper: 'Bu ay',
        ),
        _buildStatCard(
          title: 'Tüm Zamanki Ölçüm',
          value: _allTimeCount.toString(),
          icon: Icons.analytics_outlined,
          helper: 'Toplam kayıt',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required String helper,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.teal.withOpacity(0.10),
            child: Icon(icon, color: Colors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    final maxCount = _lastSevenDays.isEmpty
        ? 1
        : _lastSevenDays
            .map((item) => item.count)
            .fold<int>(1, (previous, current) {
            return current > previous ? current : previous;
          });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son 7 Gün Ölçüm Grafiği',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Günlük ölçüm sayısı dağılımı',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _lastSevenDays.map((item) {
                final normalized =
                    maxCount == 0 ? 0.0 : item.count / maxCount;
                final barHeight = 24 + (normalized * 160);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          item.count.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatShortDate(item.date),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sık kullanılan işlemlere hızlıca erişin.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onNewMeasurementTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Yeni Ölçüm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onMeasurementHistoryTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Ölçüm Geçmişi'),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
        ),
      ],
    );
  }
}

class _DailyMeasurementCount {
  final DateTime date;
  final int count;

  const _DailyMeasurementCount({
    required this.date,
    required this.count,
  });
}