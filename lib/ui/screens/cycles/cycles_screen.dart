import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/cycle_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../models/cycle.dart';
import '../../../core/constants/app_colors.dart';

/// Cycles screen - cycle management and baseline comparison
class CyclesScreen extends ConsumerStatefulWidget {
  const CyclesScreen({super.key});

  @override
  ConsumerState<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends ConsumerState<CyclesScreen> {
  String? _expandedCycleId;

  @override
  Widget build(BuildContext context) {
    final cycles = ref.watch(cyclesProvider);
    final currentCycle = ref.watch(currentCycleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create New Cycle',
            onPressed: currentCycle == null ? _showCreateCycleDialog : null,
          ),
        ],
      ),
      body: cycles.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final cycle = cycles[index];
                final isExpanded = _expandedCycleId == cycle.id;
                final isCurrent = currentCycle?.id == cycle.id;

                return _buildCycleCard(cycle, isExpanded, isCurrent);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timeline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Cycles Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first cycle to start tracking patterns',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Cycle'),
              onPressed: _showCreateCycleDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard(Cycle cycle, bool isExpanded, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(cycle.status).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(cycle.status),
                color: _getStatusColor(cycle.status),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    cycle.name ?? 'Cycle ${_formatDate(cycle.startDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCurrent)
                  Chip(
                    label: const Text('Current', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusChip(cycle.status),
                    const SizedBox(width: 8),
                    Text(
                      '${cycle.drawingCount} drawings',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Started: ${_formatDate(cycle.startDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (cycle.endDate != null)
                  Text(
                    'Ended: ${_formatDate(cycle.endDate!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expandedCycleId = isExpanded ? null : cycle.id;
                });
              },
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildCycleDetails(cycle, isCurrent),
          ],
        ],
      ),
    );
  }

  Widget _buildCycleDetails(Cycle cycle, bool isCurrent) {
    final duration = cycle.endDate != null
        ? cycle.endDate!.difference(cycle.startDate).inDays
        : DateTime.now().difference(cycle.startDate).inDays;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Duration', '$duration days'),
          _buildDetailRow('Phase', _getPhaseLabel(cycle)),
          _buildDetailRow('Drawings', cycle.drawingCount.toString()),
          if (cycle.initialBaselineId != null)
            _buildDetailRow('Initial Baseline', 'B₀ created'),
          if (cycle.rollingBaselineId != null)
            _buildDetailRow('Rolling Baseline', 'Bₙ active'),
          if (cycle.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              'Notes:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              cycle.notes!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (isCurrent && cycle.status != CycleStatus.closed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Close Cycle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                onPressed: () => _showCloseCycleDialog(cycle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(CycleStatus status) {
    return Chip(
      label: Text(
        _getStatusLabel(status),
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: _getStatusColor(status).withOpacity(0.2),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getStatusColor(CycleStatus status) {
    switch (status) {
      case CycleStatus.collecting:
        return AppColors.accentOrange;
      case CycleStatus.active:
        return AppColors.successGreen;
      case CycleStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(CycleStatus status) {
    switch (status) {
      case CycleStatus.collecting:
        return Icons.hourglass_empty;
      case CycleStatus.active:
        return Icons.check_circle;
      case CycleStatus.closed:
        return Icons.archive;
    }
  }

  String _getStatusLabel(CycleStatus status) {
    switch (status) {
      case CycleStatus.collecting:
        return 'Phase 1';
      case CycleStatus.active:
        return 'Phase 2';
      case CycleStatus.closed:
        return 'Closed';
    }
  }

  String _getPhaseLabel(Cycle cycle) {
    switch (cycle.status) {
      case CycleStatus.collecting:
        return 'Phase 1 (Building Baseline)';
      case CycleStatus.active:
        return 'Phase 2 (Active Analysis)';
      case CycleStatus.closed:
        return 'Archived';
    }
  }

  void _showCreateCycleDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Cycle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Cycle Name (optional)',
                hintText: 'e.g., "January 2025"',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this cycle',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(cycleRepositoryProvider);
              try {
                await repo.createCycle(
                  name: nameController.text.isEmpty ? null : nameController.text,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cycle created successfully!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCloseCycleDialog(Cycle cycle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Cycle'),
        content: const Text(
          'Are you sure you want to close this cycle? This will archive it and you can create a new cycle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () async {
              final repo = ref.read(cycleRepositoryProvider);
              try {
                await repo.closeCycle(cycle.id);

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cycle closed successfully!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Close Cycle'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
