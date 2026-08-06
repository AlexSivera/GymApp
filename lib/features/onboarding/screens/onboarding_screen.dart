import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';

const _totalSteps = 4;

// First-launch questionnaire: one question per screen, each skippable, that
// seeds UserSettings (name/gender/birthDate) and the first BodyWeightLogs
// entry. Reached only when UserSettingsDao.isOnboardingCompleted() is false
// at app startup (see main.dart) — never shown again once finished/skipped.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _saving = false;

  final _nameController = TextEditingController();
  String? _gender;
  DateTime _birthDate = DateTime(DateTime.now().year - 25, 1, 1);
  bool _birthDateSkipped = false;
  double _weightKg = 70;
  bool _weightSkipped = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == _totalSteps - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  void _skip() {
    switch (_step) {
      case 0:
        _nameController.clear();
      case 1:
        _gender = null;
      case 2:
        _birthDateSkipped = true;
      case 3:
        _weightSkipped = true;
    }
    _next();
  }

  void _back() => setState(() => _step--);

  Future<void> _finish() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final name = _nameController.text.trim();

    await db.userSettingsDao.updateSettings(UserSettingsCompanion(
      name: Value(name.isEmpty ? null : name),
      gender: Value(_gender),
      birthDate: Value(_birthDateSkipped ? null : _birthDate),
      onboardingCompleted: const Value(true),
    ));

    if (!_weightSkipped) {
      await db.bodyWeightDao.insertLog(BodyWeightLogsCompanion.insert(
        date: DateTime.now(),
        weightKg: _weightKg,
      ));
    }

    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_step > 0)
                    IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back))
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _totalSteps,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.curve,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(theme),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_step == _totalSteps - 1 ? 'Finalizar' : 'Continuar'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: const Text('Omitir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _NameStep(controller: _nameController);
      case 1:
        return _GenderStep(
          selected: _gender,
          onSelected: (value) => setState(() => _gender = value),
        );
      case 2:
        return _BirthDateStep(
          value: _birthDate,
          onChanged: (value) => setState(() {
            _birthDate = value;
            _birthDateSkipped = false;
          }),
        );
      default:
        return _WeightStep(
          initialValue: _weightKg,
          onChanged: (value) => setState(() {
            _weightKg = value;
            _weightSkipped = false;
          }),
        );
    }
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(child: child),
      ],
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cómo te llamas?',
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Tu nombre'),
      ),
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  static const _options = [
    (value: 'Hombre', icon: Icons.male),
    (value: 'Mujer', icon: Icons.female),
    (value: 'Otro', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cuál es tu género?',
      child: Column(
        children: [
          for (final option in _options) ...[
            _SelectableOptionCard(
              label: option.value,
              icon: option.icon,
              selected: selected == option.value,
              onTap: () => onSelected(option.value),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: selected ? theme.colorScheme.primary : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthDateStep extends StatelessWidget {
  const _BirthDateStep({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cuál es tu fecha de nacimiento?',
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: 216,
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.dark),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: value,
              maximumDate: DateTime.now(),
              minimumYear: 1930,
              onDateTimeChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}

// A horizontally-scrolling ruler, snapped under a fixed center indicator —
// drag left/right to dial in a weight, like a real dial scale.
class _WeightStep extends StatefulWidget {
  const _WeightStep({required this.initialValue, required this.onChanged});

  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  State<_WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<_WeightStep> {
  static const double _minKg = 30;
  static const double _maxKg = 200;
  static const double _pxPerKg = 100;

  late final ScrollController _controller;
  late double _currentKg;

  @override
  void initState() {
    super.initState();
    _currentKg = widget.initialValue.clamp(_minKg, _maxKg);
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpTo((_currentKg - _minKg) * _pxPerKg);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final kg = (_minKg + _controller.offset / _pxPerKg).clamp(_minKg, _maxKg);
    final rounded = (kg * 10).round() / 10;
    if (rounded != _currentKg) {
      setState(() => _currentKg = rounded);
      widget.onChanged(rounded);
    }
  }

  void _snapToNearestTenth() {
    final target = (_currentKg - _minKg) * _pxPerKg;
    if ((target - _controller.offset).abs() > 0.5) {
      _controller.animateTo(target, duration: AppMotion.fast, curve: AppMotion.curve);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepScaffold(
      title: '¿Cuánto pesas?',
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_currentKg.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 56)),
              const SizedBox(width: AppSpacing.sm),
              Text('kg',
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 90,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = constraints.maxWidth;
                final totalWidth = (_maxKg - _minKg) * _pxPerKg;
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _handleScroll();
                    if (notification is ScrollEndNotification) _snapToNearestTenth();
                    return false;
                  },
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      SingleChildScrollView(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: viewportWidth / 2),
                          child: CustomPaint(
                            size: Size(totalWidth, 90),
                            painter: _RulerPainter(
                              minKg: _minKg,
                              maxKg: _maxKg,
                              pxPerKg: _pxPerKg,
                              tickColor: theme.colorScheme.onSurfaceVariant,
                              labelStyle: theme.textTheme.bodySmall!,
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          width: 2,
                          height: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.minKg,
    required this.maxKg,
    required this.pxPerKg,
    required this.tickColor,
    required this.labelStyle,
  });

  final double minKg;
  final double maxKg;
  final double pxPerKg;
  final Color tickColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final steps = ((maxKg - minKg) * 10).round();
    for (var i = 0; i <= steps; i++) {
      final x = i * (pxPerKg / 10);
      final isMajor = i % 10 == 0;
      final isMedium = i % 5 == 0;
      final height = isMajor ? 36.0 : (isMedium ? 24.0 : 14.0);
      final paint = Paint()
        ..color = tickColor.withValues(alpha: isMajor ? 0.9 : (isMedium ? 0.6 : 0.35))
        ..strokeWidth = isMajor ? 2 : 1;
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
      if (isMajor) {
        final kg = (minKg + i / 10).round();
        final painter = TextPainter(
          text: TextSpan(text: '$kg', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x - painter.width / 2, height + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) => false;
}
