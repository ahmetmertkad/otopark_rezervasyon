import 'package:flutter/material.dart';

class ParkingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showAnniversaryBadge;
  final bool centerTitle;
  final VoidCallback? onLogoTap;

  const ParkingAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showAnniversaryBadge = false,
    this.centerTitle = false,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final fg = theme.colorScheme.onSurface;

    return AppBar(
      elevation: 6,
      backgroundColor: bg,
      foregroundColor: fg,
      centerTitle: centerTitle,
      scrolledUnderElevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoMark(onTap: onLogoTap),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          if (showAnniversaryBadge) ...[
            const SizedBox(width: 12),
            _AnniversaryBadge(),
          ],
        ],
      ),
      actions: actions,
    );
  }
}

class _LogoMark extends StatelessWidget {
  final VoidCallback? onTap;
  const _LogoMark({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Image.asset(
        'assets/images/logo_mark.png',
        width: 44,
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _AnniversaryBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/anniversary_badge.png',
      height: 28,
      fit: BoxFit.contain,
    );
  }
}
