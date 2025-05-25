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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Combates'),
        backgroundColor: Colors.red,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0, // Hacer el indicador un poco más grueso
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs,
          // isScrollable: true, // Descomenta si tienes muchas pestañas y quieres que se puedan desplazar
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage("assets/images/boxing_bg.jpg"), // Asegúrate que la ruta es correcta
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.82), BlendMode.darken),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: _tabViews,
        ),
      ),
    );
  }
}