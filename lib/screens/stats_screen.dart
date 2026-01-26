import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _dbService = DatabaseService.getInstance();
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  Map<String, dynamic>? _weeklyStats;
  bool _isLoading = true;

  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _dbService.getWeeklyStats(_currentWeekStart);
    setState(() {
      _weeklyStats = stats;
      _isLoading = false;
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadStats();
  }

  void _nextWeek() {
    final nextWeek = _currentWeekStart.add(const Duration(days: 7));
    if (nextWeek.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() {
        _currentWeekStart = nextWeek;
      });
      _loadStats();
    }
  }

  String _formatWeekRange() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (_currentWeekStart.month == weekEnd.month) {
      return '${months[_currentWeekStart.month - 1]} ${_currentWeekStart.day} - ${weekEnd.day}';
    }
    return '${months[_currentWeekStart.month - 1]} ${_currentWeekStart.day} - ${months[weekEnd.month - 1]} ${weekEnd.day}';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'NAP STATS',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.white))
            : Column(
                children: [
                  // Week navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _previousWeek,
                          icon: const Icon(Icons.chevron_left, color: AppTheme.white),
                        ),
                        Text(
                          _formatWeekRange(),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        IconButton(
                          onPressed: _nextWeek,
                          icon: Icon(
                            Icons.chevron_right,
                            color: _currentWeekStart.add(const Duration(days: 7)).isBefore(DateTime.now())
                                ? AppTheme.white
                                : AppTheme.lightGrey.withAlpha(50),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Weekly summary cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Naps',
                            value: '${_weeklyStats?['totalNaps'] ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            label: 'Total Time',
                            value: '${_weeklyStats?['totalMinutes'] ?? 0}m',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            label: 'Avg Duration',
                            value: '${(_weeklyStats?['avgDuration'] ?? 0).toStringAsFixed(0)}m',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Day-by-day bar chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _WeekChart(napsByDay: _weeklyStats?['napsByDay'] ?? {}),
                  ),

                  const SizedBox(height: 32),

                  // Nap history list
                  Expanded(
                    child: _buildNapList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNapList() {
    final records = (_weeklyStats?['records'] as List<NapRecord>?) ?? [];

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nights_stay_outlined, color: AppTheme.lightGrey.withAlpha(100), size: 48),
            const SizedBox(height: 16),
            Text(
              'No naps this week',
              style: TextStyle(
                color: AppTheme.lightGrey.withAlpha(150),
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _NapListItem(record: record);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.buttonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.lightGrey.withAlpha(180),
              fontSize: 11,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final Map<int, int> napsByDay;

  const _WeekChart({required this.napsByDay});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxNaps = napsByDay.values.fold(0, (max, v) => v > max ? v : max);
    final chartMax = maxNaps > 0 ? maxNaps : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.buttonBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Naps per day',
            style: TextStyle(
              color: AppTheme.lightGrey.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final naps = napsByDay[index] ?? 0;
              final height = naps > 0 ? (naps / chartMax) * 60 : 4.0;

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      color: naps > 0 ? AppTheme.white : AppTheme.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: AppTheme.lightGrey.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NapListItem extends StatelessWidget {
  final NapRecord record;

  const _NapListItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final time = record.startTime;
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:${time.minute.toString().padLeft(2, '0')} $period';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayStr = days[time.weekday - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.buttonBackground.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.nights_stay, color: AppTheme.lightGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayStr, $timeStr',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${record.durationMinutes} min',
            style: const TextStyle(
              color: AppTheme.lightGrey,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
