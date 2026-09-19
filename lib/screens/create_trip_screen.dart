import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../widgets/selectable_chip.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  int _travellers = 1;
  final Set<Interest> _selectedInterests = {};
  TravelStyle _travelStyle = TravelStyle.relaxed;

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
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
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

  void _submit() {
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

    final trip = Trip(
      source: _sourceController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      travellers: _travellers,
      budget: double.parse(_budgetController.text.trim()),
      interests: _selectedInterests.toList(),
      travelStyle: _travelStyle,
    );

    // Itinerary generation (mock for now) is wired in the next step.
    debugPrint('Trip created: ${trip.source} → ${trip.destination}, ${trip.durationInDays} days');
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
              const Text('Source', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ahmedabad',
                  prefixIcon: Icon(Icons.trip_origin),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a starting location' : null,
              ),
              const SizedBox(height: 20),

              const Text('Destination', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Goa',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a destination' : null,
              ),
              const SizedBox(height: 20),

              const Text('Trip Dates', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateRange,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDate == null
                        ? 'Select dates'
                        : '${_fmt(_startDate!)}  →  ${_fmt(_endDate!)}',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Travellers', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _travellers > 1
                        ? () => setState(() => _travellers--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_travellers', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(() => _travellers++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Text('Budget (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 15000',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter a budget';
                  if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),

              const Text('Travel Style', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<TravelStyle>(
                segments: const [
                  ButtonSegment(value: TravelStyle.relaxed, label: Text('Relaxed')),
                  ButtonSegment(value: TravelStyle.balanced, label: Text('Balanced')),
                  ButtonSegment(value: TravelStyle.packed, label: Text('Packed')),
                ],
                selected: {_travelStyle},
                onSelectionChanged: (value) => setState(() => _travelStyle = value.first),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Itinerary'),
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