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
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
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
