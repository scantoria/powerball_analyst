import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/cycle_providers.dart';

/// Cycles screen - cycle management and baseline comparison
class CyclesScreen extends ConsumerWidget {
  const CyclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(cyclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Create new cycle
            },
          ),
        ],
      ),
      body: cycles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Cycles Yet',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first cycle to get started'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                return Card(
                  child: ListTile(
                    title: Text('Cycle ${index + 1}'),
                    subtitle: Text(
                      'Status: ${cycle.status.name}\n'
                      'Drawings: ${cycle.drawingCount}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
