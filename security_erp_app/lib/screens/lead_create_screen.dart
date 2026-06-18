import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class LeadCreateScreen extends StatefulWidget {
  const LeadCreateScreen({super.key});

  @override
  State<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends State<LeadCreateScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taController = TextEditingController();
  
  bool _loading = false;
  bool _aiLoading = false;
  Map<String, dynamic>? _aiResult;
  List<dynamic> _scenarios = [];
  String? _selectedScenario;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    try {
      final result = await api.get('/api/v2/scenarios');
      if (result['success']) {
        setState(() {
          _scenarios = result['data'];
        });
      }
    } catch (e) {
      debugPrint('Error loading scenarios: $e');
    }
  }

  Future<void> _saveLead() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, введіть ім\'я та телефон')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });
    try {
      final result = await api.post('/api/v2/leads', {
        'lead_name': _nameController.text.trim(),
        'mobile_no': _phoneController.text.trim(),
        'object_address': _addressController.text.trim(),
        'technical_assignment': _taController.text.trim(),
        'status': 'Open',
      });
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Лід успішно створено!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка при створенні ліда: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _getAIEstimate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спочатку створіть ліда')),
      );
      return;
    }

    if (_taController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть технічне завдання для розрахунку')),
      );
      return;
    }

    setState(() {
      _aiLoading = true;
    });
    try {
      // We need to find the lead's internal ID by name first
      final leadSearch = await api.get('/api/v2/leads', params: {'filters': '[["lead_name","=","${_nameController.text}"]]'});
      final leads = leadSearch['data'] as List;
      if (leads.isEmpty) throw Exception('Лід не знайдено');
      final leadName = leads.first['name'];

      final result = await api.post('/api/v2/ai/estimate', {
        'lead_name': leadName,
        'technical_assignment': _taController.text.trim(),
      });

      if (result['success']) {
        setState(() {
          _aiResult = result['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка AI: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _aiLoading = false;
      });
    }
  }

  Future<void> _applyScenario() async {
    if (_selectedScenario == null) return;
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спочатку створіть ліда')),
      );
      return;
    }

    setState(() {
      _aiLoading = true;
    });
    try {
      final leadSearch = await api.get('/api/v2/leads', params: {'filters': '[["lead_name","=","${_nameController.text}"]]'});
      final leads = leadSearch['data'] as List;
      if (leads.isEmpty) throw Exception('Лід не знайдено');
      final leadName = leads.first['name'];

      final result = await api.post('/api/v2/scenarios/$_selectedScenario/apply', {
        'lead_name': leadName,
      });

      if (result['success']) {
        setState(() {
          _aiResult = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сценарій застосовано!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка сценарію: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новий Лід & AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Дані клієнта', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ім\'я / Назва компанії', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Адреса об\'єкта', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Text('Технічне завдання', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _taController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Опишіть, що потрібно встановити...',
                border: OutlineInputBorder(),
                hintText: 'Наприклад: 4 камери по периметру, 1 в офісі, запис на 2 тижні',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveLead,
                child: _loading ? const CircularProgressIndicator() : const Text('Створити Лід'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedScenario,
                    decoration: const InputDecoration(
                      labelText: 'Вибрати сценарій',
                      border: OutlineInputBorder(),
                    ),
                    items: _scenarios.map((s) {
                      return DropdownMenuItem<String>(
                        value: s['name'],
                        child: Text(s['scenario_name']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedScenario = v),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedScenario == null || _aiLoading) ? null : _applyScenario,
                    child: _aiLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Додати'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _aiLoading ? null : _getAIEstimate,
                icon: const Icon(Icons.auto_awesome),
                label: _aiLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Розрахувати через ШІ'),
              ),
            ),
            if (_aiResult != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              Text('Попередня пропозиція', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              _buildAIResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIResultCard() {
    final items = _aiResult!['items'] as List;
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item['quantity']} x ${item['item_code']} - ${item['reason']}')),
                  Text('${item['price']} грн'),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Разом:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_aiResult!['total_estimated_cost']} грн', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Порада інженера: ${_aiResult!['engineer_comments']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
