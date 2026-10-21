import 'package:flutter/material.dart';

/// Shows the data attributions of a map in a sheet. Use it with
/// `SiroMap(attributionEnabled: false)`, so the native engine draws no
/// attribution button of its own and the text is always ours.
class SiroAttributionButton extends StatelessWidget {
  const SiroAttributionButton({
    super.key,
    required this.attributions,
    this.color,
  });

  /// One line per data source, for example '© OpenStreetMap contributors'.
  final List<String> attributions;

  /// Colour of the info icon.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Map data',
      icon: Icon(Icons.info_outline, color: color),
      onPressed:
          () => showModalBottomSheet<void>(
            context: context,
            builder:
                (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final line in attributions)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(line),
                          ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}
