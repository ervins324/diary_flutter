import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/alerts_provider.dart';

/// Live Air Raid Alert banner showing active warning in the selected region.
class AirRaidBanner extends ConsumerWidget {
  const AirRaidBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(airRaidAlertProvider);
    final loc = AppLocalizations.of(context);

    if (!alertState.isAlertActive) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          shape: const LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 16.0),
          appearance: const LiquidGlassAppearance(
            color: Color(0x3DF43F5E), // Rose / Red frosted glass
            blur: LiquidGlassBlur(sigmaX: 16.0, sigmaY: 16.0),
          ),
          refraction: const LiquidGlassRefraction(distortion: 0.05),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0x66F43F5E), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0x33F43F5E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF4D4D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.translate('air_raid_alert'),
                      style: const TextStyle(
                        color: Color(0xFFFF4D4D),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alertState.activeRegion}: ${loc.translate('alert_active')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
