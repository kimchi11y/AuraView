import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? currentGenre;
  final String? currentYear;
  final double currentRating;
  final Function(String?, String?, double) onApply;

  const FilterBottomSheet({
    super.key,
    this.currentGenre,
    this.currentYear,
    this.currentRating = 0.0,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedGenre;
  final TextEditingController _yearController = TextEditingController();
  double _selectedRating = 0.0;

  // TMDB uses specific integer IDs for genres. Here is a basic map.
  final Map<String, String> _genres = {
    'Any': '',
    'Action': '28',
    'Comedy': '35',
    'Horror': '27',
    'Romance': '10749',
    'Sci-Fi': '878',
  };

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.currentGenre;
    _yearController.text = widget.currentYear ?? '';
    _selectedRating = widget.currentRating;
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filter Movies',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Genre Dropdown
            Text(
              'Genre',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.movie_filter),
              ),
              hint: const Text('Select a genre'),
              items: _genres.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedGenre = value),
            ),
            const SizedBox(height: 16),

            // Release Year Input
            Text(
              'Release Year',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 2023',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            // Minimum Rating Slider
            Text(
              'Minimum Rating: ${_selectedRating.toStringAsFixed(1)}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.text),
            ),
            Slider(
              value: _selectedRating,
              min: 0,
              max: 10,
              divisions: 20,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _selectedRating = value),
            ),
            const SizedBox(height: 32),

            // Apply Button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(
                  _selectedGenre,
                  _yearController.text.trim(),
                  _selectedRating,
                );
              },
              child: const Text('APPLY FILTERS'),
            ),
          ],
        ),
      ),
    );
  }
}
