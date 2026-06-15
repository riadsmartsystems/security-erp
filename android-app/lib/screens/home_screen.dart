import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'tickets_screen.dart';
import 'objects_screen.dart';
import 'equipment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    TicketsScreen(),
    ObjectsScreen(),
    EquipmentScreen(),
  ];

  final _titles = ['Головна', 'Заявки', 'Об\'єкти', 'Обладнання'];

  void _logout() async {
    await api.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() {});
          }),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1565C0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.security, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Security ERP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Field Engineer App', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Головна'),
              selected: _currentIndex == 0,
              onTap: () { setState(() => _currentIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: const Text('Заявки'),
              selected: _currentIndex == 1,
              onTap: () { setState(() => _currentIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Об\'єкти'),
              selected: _currentIndex == 2,
              onTap: () { setState(() => _currentIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Обладнання'),
              selected: _currentIndex == 3,
              onTap: () { setState(() => _currentIndex = 3); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Вихід', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Головна'),
          NavigationDestination(icon: Icon(Icons.confirmation_number), label: 'Заявки'),
          NavigationDestination(icon: Icon(Icons.business), label: 'Об\'єкти'),
          NavigationDestination(icon: Icon(Icons.build), label: 'Обладнання'),
        ],
      ),
    );
  }
}
