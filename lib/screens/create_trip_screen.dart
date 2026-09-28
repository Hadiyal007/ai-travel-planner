import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme.dart';
import '../models/trip.dart';
import '../widgets/selectable_chip.dart';
import '../widgets/place_autocomplete_field.dart';
import '../firebase/auth_providers.dart';
import '../firebase/trip_providers.dart';
import '../providers/itinerary_provider.dart';
import '../utils/budget_validator.dart';
import 'itinerary_screen.dart';


class CreateTripScreen extends ConsumerStatefulWidget {
  final String? prefilledDestination;
  const CreateTripScreen({super.key, this.prefilledDestination});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _travellers = 1;
  final Set<Interest> _selectedInterests = {};
  TravelStyle _travelStyle = TravelStyle.relaxed;
  bool _isSaving = false;

  static const _interestMeta = {
    Interest.beaches: (label: 'Beaches', icon: Icons.beach_access),
    Interest.food: (label: 'Food', icon: Icons.restaurant),
    Interest.adventure: (label: 'Adventure', icon: Icons.terrain),
    Interest.culture: (label: 'Culture', icon: Icons.museum),
    Interest.nightlife: (label: 'Nightlife', icon: Icons.nightlife),
    Interest.nature: (label: 'Nature', icon: Icons.park),
    Interest.shopping: (label: 'Shopping', icon: Icons.shopping_bag),
    Interest.history: (label: 'History', icon: Icons.account_balance),
  };
  @override
  void initState() {
    super.initState();
    if (widget.prefilledDestination != null) {
      _destinationController.text = widget.prefilledDestination!;
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }


  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _analyseTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceController.text.trim().toLowerCase() ==
        _destinationController.text.trim().toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination can\'t be the same')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select trip dates')));
      return;
    }
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick at least one interest')));
      return;
    }

    final budget = double.parse(_budgetController.text.trim());
    final durationInDays = _endDate!.difference(_startDate!).inDays + 1;
    final budgetWarning = BudgetValidator.check(
      budget: budget,
      durationInDays: durationInDays,
      travellers: _travellers,
    );
    if (budgetWarning != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(budgetWarning)));
      return;
    }

    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in again to continue')));
      return;
    }

    final trip = Trip(
      source: _sourceController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      travellers: _travellers,
      budget: budget,
      interests: _selectedInterests.toList(),
      travelStyle: _travelStyle,
      specialRequests: _specialRequestsController.text.trim().isEmpty
          ? null
          : _specialRequestsController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(itineraryProvider.notifier).generate(trip);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ItineraryScreen()),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan a Trip')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                icon: Icons.alt_route,
                title: 'Route',
                children: [
                  PlaceAutocompleteField(
                    controller: _sourceController,
                    label: 'Source',
                    hint: 'e.g. Ahmedabad',
                    icon: Icons.trip_origin,
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a starting location' : null,
                  ),
                  const SizedBox(height: 18),
                  PlaceAutocompleteField(
                    controller: _destinationController,
                    label: 'Destination',
                    hint: 'e.g. Goa',
                    icon: Icons.place_outlined,
                    validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a destination' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.calendar_today_outlined,
                title: 'Dates & Travellers',
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Trip Dates',
                        prefixIcon: Icon(Icons.date_range_outlined),
                      ),
                      child: Text(
                        _startDate == null
                            ? 'Select dates'
                            : '${_fmt(_startDate!)}  →  ${_fmt(_endDate!)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Travellers', style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      _TravellerStepper(
                        count: _travellers,
                        onDecrement: _travellers > 1
                            ? () => setState(() => _travellers--)
                            : null,
                        onIncrement: () => setState(() => _travellers++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.currency_rupee,
                title: 'Budget',
                children: [
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total budget for the trip',
                      hintText: 'e.g. 15000',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Enter a budget';
                      if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.interests_outlined,
                title: 'Interests',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Interest.values.map((interest) {
                      final meta = _interestMeta[interest]!;
                      final selected = _selectedInterests.contains(interest);
                      return SelectableChip(
                        label: meta.label,
                        icon: meta.icon,
                        selected: selected,
                        onTap: () => setState(() {
                          selected
                              ? _selectedInterests.remove(interest)
                              : _selectedInterests.add(interest);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.tune,
                title: 'Travel Style',
                children: [
                  SegmentedButton<TravelStyle>(
                    segments: const [
                      ButtonSegment(value: TravelStyle.relaxed, label: Text('Relaxed')),
                      ButtonSegment(value: TravelStyle.balanced, label: Text('Balanced')),
                      ButtonSegment(value: TravelStyle.packed, label: Text('Packed')),
                    ],
                    selected: {_travelStyle},
                    onSelectionChanged: (value) => setState(() => _travelStyle = value.first),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                icon: Icons.edit_note_outlined,
                title: 'Anything specific?',
                children: [
                  TextFormField(
                    controller: _specialRequestsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                      'e.g. prefer flights over trains, want to stay near Baga Beach, vegetarian food only',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _analyseTrip,
                icon: _isSaving
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isSaving ? 'Planning your trip...' : 'Analyse Trip'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

/// Groups a labeled section of the form into a card with a small icon
/// badge — turns a long flat list of fields into scannable sections,
/// consistent with the app's other card-based surfaces.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.marigold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.marigoldDeep),
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A compact -/count/+ stepper, replacing plain loose icon buttons with
/// a single bounded control that reads as one input rather than three
/// disconnected taps.
class _TravellerStepper extends StatelessWidget {
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _TravellerStepper({
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.hairline),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 18),
            color: AppTheme.indigoNight,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 18),
            color: AppTheme.indigoNight,
          ),
        ],
      ),
    );
  }
}