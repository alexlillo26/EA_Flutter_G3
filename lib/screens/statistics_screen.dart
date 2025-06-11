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
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/boxing_bg.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.82), BlendMode.darken),
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
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildStatCard('Oponente Más Frecuente', statistics['mostFrequentOpponent'], Icons.person),
                  const SizedBox(height: 16),
                  _buildStatCard('Gimnasio Más Frecuente', statistics['mostFrequentGym'], Icons.fitness_center),
                  const SizedBox(height: 16),
                  _buildFightsPerMonthCard(statistics['fightsPerMonth']),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.grey[850]?.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: Colors.red, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
      color: Colors.grey[850]?.withOpacity(0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peleas por Mes',
              style: TextStyle(
                  color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (fightsPerMonth.isEmpty)
              const Text('No hay datos mensuales.', style: TextStyle(color: Colors.white))
            else
              ...fightsPerMonth.entries.map((entry) {
                final parts = entry.key.split('-');
                final year = parts[0];
                final month = monthNames[parts[1]] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$month $year', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Text('${entry.value} ${entry.value == 1 ? "pelea" : "peleas"}', style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
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