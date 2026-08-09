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
      child: Align(
        alignment: Alignment.topCenter,
        child: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
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

class _BirthDateStep extends StatefulWidget {
  const _BirthDateStep({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_BirthDateStep> createState() => _BirthDateStepState();
}

class _BirthDateStepState extends State<_BirthDateStep> {
  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static const _minYear = 1930;
  final int _maxYear = DateTime.now().year;

  late int _day;
  late int _month;
  late int _year;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  int get _daysInMonth => DateUtils.getDaysInMonth(_year, _month);

  @override
  void initState() {
    super.initState();
    _day = widget.value.day;
    _month = widget.value.month;
    _year = widget.value.year.clamp(_minYear, _maxYear);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(initialItem: _year - _minYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // Changing month/year can push the selected day past the new month's
  // length (e.g. 31 -> feb); clamp it and snap the day wheel to match.
  void _clampDay() {
    final maxDay = _daysInMonth;
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayController.hasClients) _dayController.jumpToItem(_day - 1);
      });
    }
  }

  void _onDayChanged(int index) {
    setState(() => _day = index + 1);
    widget.onChanged(DateTime(_year, _month, _day));
  }

  void _onMonthChanged(int index) {
    setState(() {
      _month = index + 1;
      _clampDay();
    });
    widget.onChanged(DateTime(_year, _month, _day));
  }

  void _onYearChanged(int index) {
    setState(() {
      _year = _minYear + index;
      _clampDay();
    });
    widget.onChanged(DateTime(_year, _month, _day));
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cuál es tu fecha de nacimiento?',
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          height: _WheelColumn.totalHeight,
          child: Row(
            children: [
              Expanded(
                child: _WheelColumn(
                  controller: _dayController,
                  itemCount: _daysInMonth,
                  selectedIndex: _day - 1,
                  labelBuilder: (i) => '${i + 1}',
                  onChanged: _onDayChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _WheelColumn(
                  controller: _monthController,
                  itemCount: 12,
                  selectedIndex: _month - 1,
                  labelBuilder: (i) => _months[i],
                  onChanged: _onMonthChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _WheelColumn(
                  controller: _yearController,
                  itemCount: _maxYear - _minYear + 1,
                  selectedIndex: _year - _minYear,
                  labelBuilder: (i) => '${_minYear + i}',
                  onChanged: _onYearChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A single day/month/year wheel: a rounded card (matching the app's
// surfaceContainerHighest boxes elsewhere) housing a CupertinoPicker, with
// the centered value styled larger/bolder than its neighbours.
class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;

  static const double itemExtent = 52;
  static const double totalHeight = itemExtent * 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: itemExtent,
          diameterRatio: 1.4,
          squeeze: 1.1,
          selectionOverlay: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          onSelectedItemChanged: onChanged,
          children: [
            for (var i = 0; i < itemCount; i++)
              Center(
                child: Text(
                  labelBuilder(i),
                  style: TextStyle(
                    fontSize: i == selectedIndex ? 24 : 18,
                    fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w400,
                    color: i == selectedIndex
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
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
