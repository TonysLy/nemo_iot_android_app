import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../utils/themes.dart';

class InputWidgetNormal extends StatelessWidget {
  final Widget? leftWidget;
  final TextEditingController? controller;
  final String? placeholder;
  final Widget? rightWidget;
  final List<TextInputFormatter>? inputFormatters;
  final OverlayVisibilityMode clearButtonMode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final bool dividingLine;
  final EdgeInsets textFieldPadding;
  final double leftWidgetWidth;
  final Color? color;

  final bool textColorSet;
  final Color? textColor;

  final int? maxLength;

  const InputWidgetNormal({
    Key? key,
    this.leftWidget,
    this.controller,
    this.placeholder,
    this.rightWidget,
    this.inputFormatters,
    this.clearButtonMode = OverlayVisibilityMode.never,
    this.keyboardType,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.autofocus = false,
    this.autofillHints,
    this.onChanged,
    this.dividingLine = true,
    this.textFieldPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.leftWidgetWidth = 50,
    this.maxLength,
    this.color,
    required this.textColorSet,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(),
      child: Row(
        children: [
          Visibility(
            visible: dividingLine,
            child: Container(
              color: const Color(0xFFE0E0E0),
              height: 20,
              width: 1,
            ),
          ),
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              padding: textFieldPadding,
              placeholder: placeholder,
              placeholderStyle: Themes.fontSize14FontWeight400.copyWith(
                color: textColorSet ? textColor : const Color(0xFF919499),
              ),
              textAlign: TextAlign.right,
              inputFormatters: inputFormatters,
              keyboardType: keyboardType,
              obscureText: obscureText,
              autocorrect: autocorrect,
              autofillHints: autofillHints,
              smartDashesType: smartDashesType,
              smartQuotesType: smartQuotesType,
              autofocus: autofocus,
              textInputAction: TextInputAction.next,
              onChanged: onChanged,
              maxLength: maxLength,
            ),
          ),
        ],
      ),
    );
  }
}
