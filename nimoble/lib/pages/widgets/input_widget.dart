import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../utils/themes.dart';

class InputWidget extends StatelessWidget {
  final Widget leftWidget;
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
  final Color borderColor;

  final int? maxLength;

  const InputWidget({
    Key? key,
    required this.leftWidget,
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
    this.borderColor = const Color(0xFFE0E0E0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
        ),
        borderRadius: BorderRadius.circular(4),
        color: CupertinoColors.white,
      ),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: leftWidgetWidth,
            child: leftWidget,
          ),
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
                color: const Color(0xFF919499),
              ),
              inputFormatters: inputFormatters,
              clearButtonMode: clearButtonMode,
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
          Builder(
            builder: (context) {
              if (rightWidget != null) {
                return rightWidget!;
              } else {
                return Container();
              }
            },
          )
        ],
      ),
    );
  }
}
