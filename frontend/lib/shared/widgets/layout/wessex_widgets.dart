import 'package:flutter/material.dart';
import 'package:wesrugby/core/config/colors.dart';

const double kWessexMaxContentWidth = 1180;

/// Widget de background común para toda la aplicación Wessex Rugby
/// Mantiene consistencia visual con imagen de fondo y overlay
class WessexBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final bool showOverlay;
  final double? maxContentWidth;

  const WessexBackground({
    super.key,
    required this.child,
    this.opacity = 0.3,
    this.showOverlay = true,
    this.maxContentWidth = kWessexMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (maxContentWidth != null) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth!,
          ),
          child: SizedBox(
            width: double.infinity,
            child: child,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          'assets/icon/background.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    WessexColors.midnightNavy,
                    WessexColors.deepRoyalBlue,
                    WessexColors.midnightNavy.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
        // Dark overlay for better readability
        if (showOverlay)
          Container(color: WessexColors.darkGrape.withOpacity(opacity)),
        // Content
        content,
      ],
    );
  }
}

/// AppBar personalizada para Wessex Rugby con gradiente
class WessexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;
  final double? titleSpacing;
  final EdgeInsetsGeometry? padding;

  const WessexAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.elevation = 0,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.toolbarHeight,
    this.titleSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [WessexColors.midnightNavy, WessexColors.deepRoyalBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow:
            elevation > 0
                ? [
                  BoxShadow(
                    color: WessexColors.darkGrape.withOpacity(0.3),
                    blurRadius: elevation * 2,
                    offset: Offset(0, elevation),
                  ),
                ]
                : null,
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: WessexColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: WessexColors.white),
        elevation: 0,
        centerTitle: centerTitle,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        toolbarHeight: toolbarHeight,
        titleSpacing: titleSpacing,
      ),
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    final baseHeight = toolbarHeight ?? kToolbarHeight;
    final paddingHeight =
        padding is EdgeInsets ? (padding as EdgeInsets).vertical : 0;
    return Size.fromHeight(baseHeight + bottomHeight + paddingHeight);
  }
}

/// Card personalizada para Wessex Rugby con design system
class WessexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? opacity;

  const WessexCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 4,
    this.borderRadius,
    this.backgroundColor,
    this.opacity = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (backgroundColor ?? WessexColors.white).withOpacity(
          opacity ?? 0.95,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            elevation != null && elevation! > 0
                ? [
                  BoxShadow(
                    color: WessexColors.darkGrape.withOpacity(0.2),
                    blurRadius: elevation! * 2,
                    offset: Offset(0, elevation! / 2),
                  ),
                ]
                : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

/// Botón principal de Wessex Rugby
class WessexButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const WessexButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return SizedBox(
      width: width,
      height: height ?? (isDesktop ? 56 : (isTablet ? 50 : 48)),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? WessexColors.primaryAction,
          foregroundColor: textColor ?? WessexColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : (isTablet ? 20 : 16),
                vertical: isDesktop ? 16 : (isTablet ? 14 : 12),
              ),
          disabledBackgroundColor: WessexColors.maximumGrayMint,
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: textColor ?? WessexColors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: isDesktop ? 24 : (isTablet ? 22 : 20)),
                      SizedBox(width: isDesktop ? 12 : (isTablet ? 10 : 8)),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

/// Sección de título con estilo Wessex Rugby
class WessexSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final double? fontSize;

  const WessexSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDesktop = screenSize.width > 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize ?? (isDesktop ? 24 : (isTablet ? 22 : 20)),
            fontWeight: FontWeight.bold,
            color: titleColor ?? WessexColors.white,
            shadows: [
              Shadow(
                color: WessexColors.darkGrape.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
              color: (subtitleColor ?? WessexColors.white).withOpacity(0.9),
              shadows: [
                Shadow(
                  color: WessexColors.darkGrape.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
