import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../services/combat_service.dart';
import '../models/combat_invitation_model.dart';
import '../session.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final CombatService _combatService = CombatService();
  Future<List<CombatInvitation>>? _combatHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadCombatHistory();
  }

  void _loadCombatHistory() {
    if (mounted) {
      setState(() {
        _combatHistoryFuture = _combatService.getCombatHistory();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Combate'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/boxing_bg.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.85), BlendMode.darken),
          ),
        ),
        child: FutureBuilder<List<CombatInvitation>>(
          future: _combatHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.red));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar las estadísticas: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No hay datos de combates para mostrar estadísticas.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final combatHistory = snapshot.data!;
            final statistics = _calculateStatistics(combatHistory);

            return RefreshIndicator(
              onRefresh: () async {
                _loadCombatHistory();
              },
              color: Colors.red,
              backgroundColor: Colors.black,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // --- Cabecera temática ---
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 10),
                        const Text(
                          'Tus estadísticas',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // --- Tarjetas estadísticas ---
                  _buildStatCard(
                    'Oponente Más Frecuente',
                    statistics['mostFrequentOpponent'],
                    Icons.sports_mma,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 18),
                  _buildStatCard(
                    'Gimnasio Más Frecuente',
                    statistics['mostFrequentGym'],
                    Icons.fitness_center,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 18),
                  _buildFightsPerMonthCard(statistics['fightsPerMonth']),
                  const SizedBox(height: 24),
                  // --- Pie de página temático ---
                  Center(
                    child: Text(
                      'Face2Face Boxing',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                        fontSize: 16,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
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

  Map<String, dynamic> _calculateStatistics(List<CombatInvitation> history) {
    if (history.isEmpty) {
      return {
        'mostFrequentOpponent': 'N/A',
        'mostFrequentGym': 'N/A',
        'fightsPerMonth': <String, int>{},
      };
    }

    // Oponente más frecuente
    final opponentCounts = groupBy(history, (CombatInvitation combat) {
      return combat.creatorId == Session.userId ? combat.opponentName : combat.creatorName;
    }).map((key, value) => MapEntry(key, value.length));

    final mostFrequentOpponent = opponentCounts.entries.isEmpty ? 'N/A' : opponentCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Gimnasio más frecuente
    final gymCounts = groupBy(history, (CombatInvitation combat) => combat.gymName)
        .map((key, value) => MapEntry(key, value.length));
    
    final mostFrequentGym = gymCounts.entries.isEmpty ? 'N/A' : gymCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;


    // Peleas por mes
    final fightsPerMonth = groupBy(history, (CombatInvitation combat) {
      return DateFormat('yyyy-MM').format(combat.date);
    }).map((key, value) => MapEntry(key, value.length));

    // Sort by date
    final sortedFightsPerMonth = Map.fromEntries(
        fightsPerMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));


    return {
      'mostFrequentOpponent': mostFrequentOpponent,
      'mostFrequentGym': mostFrequentGym,
      'fightsPerMonth': sortedFightsPerMonth,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = Colors.redAccent}) {
    return Card(
      color: Colors.black.withOpacity(0.82),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFightsPerMonthCard(Map<String, int> fightsPerMonth) {
    final monthNames = {
      '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
      '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
      '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
    };

    return Card(
      color: Colors.black.withOpacity(0.82),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_month, color: Colors.redAccent, size: 28),
                SizedBox(width: 12),
                Text(
                  'Peleas por Mes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (fightsPerMonth.isEmpty)
              const Text('No hay datos mensuales.', style: TextStyle(color: Colors.white))
            else
              ...fightsPerMonth.entries.map((entry) {
                final parts = entry.key.split('-');
                final year = parts[0];
                final month = monthNames[parts[1]] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.redAccent.withOpacity(0.7), size: 10),
                          const SizedBox(width: 8),
                          Text('$month $year', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      Text(
                        '${entry.value} ${entry.value == 1 ? "pelea" : "peleas"}',
                        style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}