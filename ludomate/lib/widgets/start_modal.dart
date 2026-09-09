import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StartModal extends StatelessWidget {
  const StartModal({super.key, required this.onModeSelected});

  final void Function(String mode) onModeSelected;

  static const List<String> _modes = [
    'You & Computer',
    'Tournament',
    'Family',
    'Multiplayer',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: _modes
                    .map((mode) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _modeButton(context, mode),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Expanded(
            child: Text(
              'Start',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(BuildContext context, String mode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        onPressed: () {
          Navigator.of(context).pop();
          onModeSelected(mode);
        },
        child: Text(
          mode,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
