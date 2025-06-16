import 'package:flutter/material.dart';
// Asegúrate que las rutas a tus widgets de pestañas sean correctas.
// Es una buena práctica tenerlos en una subcarpeta 'widgets' o 'tabs'.
// Por ejemplo: import '../widgets/tabs/received_invitations_tab.dart';

import 'package:face2face_app/widgets/received_invitations_tab.dart';
import 'package:face2face_app/widgets/sent_invitations_tab.dart';
import 'package:face2face_app/widgets/upcoming_combats_tab.dart';
import 'package:face2face_app/widgets/combat_history_tab.dart';

class CombatManagementScreen extends StatefulWidget {
  const CombatManagementScreen({super.key});

  @override
  State<CombatManagementScreen> createState() => _CombatManagementScreenState();
}

class _CombatManagementScreenState extends State<CombatManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.mark_email_unread_outlined), text: 'Recibidas'),
    Tab(icon: Icon(Icons.send_and_archive_outlined), text: 'Enviadas'),
    Tab(icon: Icon(Icons.event_available_outlined), text: 'Próximos'),
    Tab(icon: Icon(Icons.history_toggle_off_outlined), text: 'Historial'),
  ];

  final List<Widget> _tabViews = [
    ReceivedInvitationsTab(),
    SentInvitationsTab(),
    UpcomingCombatsTab(),
    CombatHistoryTab(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/images/boxing_bg.jpg"),
          fit: BoxFit.cover,
        ),
        color: Colors.black.withOpacity(0.82),
      ),
      child: Center(
        child: Card(
          color: Colors.black.withOpacity(0.85),
          elevation: 10,
          // Bajamos el recuadro añadiendo más margen superior
          margin: const EdgeInsets.fromLTRB(12, 56, 12, 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Si quieres un AppBar aquí, ponlo así:
                // AppBar(
                //   backgroundColor: Colors.transparent,
                //   elevation: 0,
                //   automaticallyImplyLeading: Navigator.of(context).canPop(),
                //   title: const Text('Gestión de Combates', style: TextStyle(color: Colors.red)),
                // ),
                // Pero normalmente NO pongas AppBar aquí, deja que el global lo gestione.
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.red.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    indicatorColor: Colors.redAccent,
                    indicatorWeight: 3.0,
                    labelColor: Colors.redAccent,
                    unselectedLabelColor: Colors.white.withOpacity(0.8),
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    tabs: _tabs,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: TabBarView(
                        controller: _tabController,
                        children: _tabViews,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}