import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/cycle_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/baseline_providers.dart';
import '../../../providers/analysis_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/number_ball.dart';

/// Picker screen - number selection and recommendations
class PickerScreen extends ConsumerStatefulWidget {
  const PickerScreen({super.key});

  @override
  ConsumerState<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends ConsumerState<PickerScreen> {
  final Set<int> _selectedWhiteBalls = {};
  int? _selectedPowerball;
  DateTime? _targetDrawDate;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final currentCycle = ref.watch(currentCycleProvider);
    final activeBaseline = ref.watch(activeBaselineProvider);

    if (currentCycle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Number Picker'),
        ),
        body: _buildNoCycleState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Number Picker'),
        actions: [
          if (_selectedWhiteBalls.isNotEmpty || _selectedPowerball != null)
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Numbers Display
            _buildSelectedNumbersCard(),
            const SizedBox(height: 24),

            // Auto-Pick Button
            if (activeBaseline != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Auto-Pick'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSaving ? null : _generateAutoPick,
                  ),
                ),
              ),

            // White Balls Selection
            Text(
              'Select 5 White Balls (1-69)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${_selectedWhiteBalls.length}/5 selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildWhiteBallsGrid(),
            const SizedBox(height: 24),

            // Powerball Selection
            Text(
              'Select 1 Powerball (1-26)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              _selectedPowerball != null ? '1/1 selected' : '0/1 selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPowerballsGrid(),
            const SizedBox(height: 24),

            // Target Draw Date
            _buildTargetDateSelector(),
            const SizedBox(height: 24),

            // Save Button
            _buildSaveButton(currentCycle.id),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCycleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 80,
              color: AppColors.warningYellow,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Cycle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a cycle before selecting numbers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedNumbersCard() {
    final bool isValid = _selectedWhiteBalls.length == 5 && _selectedPowerball != null;

    return Card(
      color: isValid
          ? AppColors.successGreen.withOpacity(0.1)
          : AppColors.warningYellow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.info_outline,
                  color: isValid ? AppColors.successGreen : AppColors.warningYellow,
                ),
                const SizedBox(width: 8),
                Text(
                  isValid ? 'Pick Ready!' : 'Select Your Numbers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // White Balls Display
            if (_selectedWhiteBalls.isNotEmpty) ...[
              Text(
                'White Balls',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_selectedWhiteBalls.toList()..sort())
                    .map((num) => NumberBall(
                          number: num,
                          isPowerball: false,
                          size: 40,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'No white balls selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
            ],

            // Powerball Display
            if (_selectedPowerball != null) ...[
              Text(
                'Powerball',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              NumberBall(
                number: _selectedPowerball!,
                isPowerball: true,
                size: 40,
              ),
            ] else ...[
              Text(
                'No powerball selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteBallsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 69,
          itemBuilder: (context, index) {
            final number = index + 1;
            final isSelected = _selectedWhiteBalls.contains(number);

            return GestureDetector(
              onTap: () => _toggleWhiteBall(number),
              child: NumberBall(
                number: number,
                isPowerball: false,
                size: 40,
                isSelected: isSelected,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPowerballsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 26,
          itemBuilder: (context, index) {
            final number = index + 1;
            final isSelected = _selectedPowerball == number;

            return GestureDetector(
              onTap: () => _selectPowerball(number),
              child: NumberBall(
                number: number,
                isPowerball: true,
                size: 40,
                isSelected: isSelected,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTargetDateSelector() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Target Draw Date'),
        subtitle: Text(
          _targetDrawDate != null
              ? _formatDate(_targetDrawDate!)
              : 'Select drawing date',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectTargetDate,
      ),
    );
  }

  Widget _buildSaveButton(String cycleId) {
    final bool canSave = _selectedWhiteBalls.length == 5 &&
        _selectedPowerball != null &&
        _targetDrawDate != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check),
        label: Text(_isSaving ? 'Saving...' : 'Save Pick'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: canSave ? AppColors.primaryBlue : Colors.grey,
        ),
        onPressed: canSave && !_isSaving ? () => _savePick(cycleId) : null,
      ),
    );
  }

  void _toggleWhiteBall(int number) {
    setState(() {
      if (_selectedWhiteBalls.contains(number)) {
        _selectedWhiteBalls.remove(number);
      } else if (_selectedWhiteBalls.length < 5) {
        _selectedWhiteBalls.add(number);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only select 5 white balls'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _selectPowerball(int number) {
    setState(() {
      _selectedPowerball = number;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedWhiteBalls.clear();
      _selectedPowerball = null;
      _targetDrawDate = null;
    });
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDrawDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Target Draw Date',
    );

    if (picked != null) {
      setState(() {
        _targetDrawDate = picked;
      });
    }
  }

  Future<void> _savePick(String cycleId) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = ref.read(pickRepositoryProvider);

      await repo.createPick(
        cycleId: cycleId,
        whiteBalls: _selectedWhiteBalls.toList()..sort(),
        powerball: _selectedPowerball!,
        targetDrawDate: _targetDrawDate!,
        isAutoPick: false,
        isPreliminary: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pick saved successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // Clear selection after successful save
        _clearSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pick: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _generateAutoPick() async {
    final currentCycle = ref.read(currentCycleProvider);
    final activeBaseline = ref.read(activeBaselineProvider);

    if (currentCycle == null || activeBaseline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active cycle or baseline available'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final generator = ref.read(pickGeneratorProvider);
      final repo = ref.read(pickRepositoryProvider);

      // Determine if this is a preliminary pick
      final isPhase1 = ref.read(isPhase1Provider);

      // Generate the auto-pick
      final autoPick = await generator.generateAutoPick(
        cycleId: currentCycle.id,
        baseline: activeBaseline,
        targetDrawDate: _targetDrawDate ?? DateTime.now().add(const Duration(days: 3)),
        isPreliminary: isPhase1,
      );

      // Save it
      await repo.save(autoPick);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auto-pick generated! ${autoPick.explanation}',
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );

        // Populate the form with generated numbers
        setState(() {
          _selectedWhiteBalls.clear();
          _selectedWhiteBalls.addAll(autoPick.whiteBalls);
          _selectedPowerball = autoPick.powerball;
          _targetDrawDate = autoPick.targetDrawDate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating auto-pick: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
