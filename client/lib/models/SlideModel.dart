import 'package:flutter/cupertino.dart';

class SlideData {
  final String title;
  final String titleTag;
  final String linkText;
  final IconData icon;
  final Color iconColor;
  final String mainText;
  final String subText;
  final String duration;
  final VoidCallback? onLinkTap;
  final VoidCallback? onButtonTap;

  SlideData({
    required this.title,
    required this.titleTag,
    required this.linkText,
    required this.icon,
    required this.iconColor,
    required this.mainText,
    required this.subText,
    required this.duration,
    this.onLinkTap,
    this.onButtonTap,
  });
}