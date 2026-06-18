import 'package:flutter/material.dart';

class VisitProgressStepper extends StatelessWidget {
  final String status;

  const VisitProgressStepper({super.key, required this.status});

  List<Map<String, dynamic>> get _steps => [
    {'label': 'План', 'status': 'planned'},
    {'label': 'Доїзд', 'status': 'on_route'},
    {'label': 'Прибуття', 'status': 'arrived'},
    {'label': 'Робота', 'status': 'working'},
    {'label': 'Фініш', 'status': 'completed'},
  ];

  int _getCurrentStepIndex() {
    final index = _steps.indexWhere((s) => s['status'] == status);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentStepIndex();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_steps.length, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex;
        final color = isCurrent ? Colors.blue : (isCompleted ? Colors.green : Colors.grey);

        return Expanded(
          child: Row(
            children: [
              // Step circle
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: color,
                    child: isCompleted 
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[index]['label'],
                    style: TextStyle(fontSize: 9, color: isCurrent ? Colors.blue : Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (index < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentIndex ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
