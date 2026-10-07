import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import '../models/language.dart';

class LanguagePill extends StatelessWidget {
  final Language sourceLang;
  final Language targetLang;
  final String? detectedBadge;
  final String? sourceCustomLabel;
  final bool allowSourceSelection;
  final bool isOneWay;
  final VoidCallback onSourceTap;
  final VoidCallback onTargetTap;
  final VoidCallback? onSwapTap;

  const LanguagePill({
    super.key,
    required this.sourceLang,
    required this.targetLang,
    this.detectedBadge,
    this.sourceCustomLabel,
    this.allowSourceSelection = true,
    this.isOneWay = false,
    required this.onSourceTap,
    required this.onTargetTap,
    this.onSwapTap,
  });

  @override
  Widget build(BuildContext context) {
    final srcName = sourceCustomLabel ?? sourceLang.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source Language
          InkWell(
            onTap: onSourceTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: Text(
                      srcName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (detectedBadge != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        detectedBadge!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  if (allowSourceSelection) ...[
                    const SizedBox(width: 3),
                    const Icon(CupertinoIcons.chevron_down, size: 11, color: AppTheme.textSecondary),
                  ],
                ],
              ),
            ),
          ),

          // Divider / Swap / Direction Arrow Button
          if (isOneWay)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(CupertinoIcons.arrow_right, size: 12, color: AppTheme.textSecondary),
            )
          else
            IconButton(
              onPressed: onSwapTap,
              icon: const Icon(CupertinoIcons.arrow_right_arrow_left, size: 13, color: AppTheme.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              splashRadius: 16,
            ),

          // Target Language
          InkWell(
            onTap: onTargetTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 105),
                    child: Text(
                      targetLang.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(CupertinoIcons.chevron_down, size: 11, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
