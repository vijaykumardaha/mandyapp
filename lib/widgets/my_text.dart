import 'package:flutter/material.dart';

class MyText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final double? lineHeight;
  final TextDecoration? decoration;
  final bool softWrap;

  const MyText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.lineHeight,
    this.decoration,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    
    return Text(
      text,
      style: defaultStyle.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: lineHeight,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  // Predefined text styles
  static TextStyle get displayLargeStyle => const TextStyle(fontSize: 57, fontWeight: FontWeight.w400);
  static TextStyle get displayMediumStyle => const TextStyle(fontSize: 45, fontWeight: FontWeight.w400);
  static TextStyle get displaySmallStyle => const TextStyle(fontSize: 36, fontWeight: FontWeight.w400);
  static TextStyle get headlineLargeStyle => const TextStyle(fontSize: 32, fontWeight: FontWeight.w400);
  static TextStyle get headlineMediumStyle => const TextStyle(fontSize: 28, fontWeight: FontWeight.w400);
  static TextStyle get headlineSmallStyle => const TextStyle(fontSize: 24, fontWeight: FontWeight.w400);
  static TextStyle get titleLargeStyle => const TextStyle(fontSize: 22, fontWeight: FontWeight.w500);
  static TextStyle get titleMediumStyle => const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static TextStyle get titleSmallStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle get bodyLargeStyle => const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMediumStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmallStyle => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get labelLargeStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle get labelMediumStyle => const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle get labelSmallStyle => const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // Factory constructors for common text styles
  factory MyText.displayLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.headlineLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.titleLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.bodyLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.bodyMedium(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.bodySmall(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory MyText.labelLarge(
    String text, {
    Key? key,
    Color? color,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return MyText(
      text,
      key: key,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      letterSpacing: 0.1,
    );
  }

  
  // Shorthand getters
  static MyText get displayLargeText => const MyText('', fontSize: 57, fontWeight: FontWeight.w400);
  static MyText get displayMediumText => const MyText('', fontSize: 45, fontWeight: FontWeight.w400);
  static MyText get displaySmallText => const MyText('', fontSize: 36, fontWeight: FontWeight.w400);
  static MyText get headlineLargeText => const MyText('', fontSize: 32, fontWeight: FontWeight.w400);
  static MyText get headlineMediumText => const MyText('', fontSize: 28, fontWeight: FontWeight.w400);
  static MyText get headlineSmallText => const MyText('', fontSize: 24, fontWeight: FontWeight.w400);
  static MyText get titleLargeText => const MyText('', fontSize: 22, fontWeight: FontWeight.w500);
  static MyText get titleMediumText => const MyText('', fontSize: 16, fontWeight: FontWeight.w500);
  static MyText get titleSmallText => const MyText('', fontSize: 14, fontWeight: FontWeight.w500);
  static MyText get bodyLargeText => const MyText('', fontSize: 16, fontWeight: FontWeight.w400);
  static MyText get bodyMediumText => const MyText('', fontSize: 14, fontWeight: FontWeight.w400);
  static MyText get bodySmallText => const MyText('', fontSize: 12, fontWeight: FontWeight.w400);
  static MyText get labelLargeText => const MyText('', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1);
  static MyText get labelMediumText => const MyText('', fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static MyText get labelSmallText => const MyText('', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);
}
