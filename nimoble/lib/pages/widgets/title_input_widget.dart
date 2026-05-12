import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../utils/themes.dart';
import 'line_widget.dart';

class VerticalTitleInputWidget extends StatelessWidget {
  final String title;
  final EdgeInsets? margin;
  final double height;
  final TextEditingController? controller;
  final String? placeholder;
  // final Widget? rightWidget;
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
  final EdgeInsets textFieldPadding;
  final Color bottomLineColor;
  final int? maxLength;
  const VerticalTitleInputWidget(
      {Key? key,
      required this.title,
      this.height = 62,
      this.margin = EdgeInsets.zero,
      this.controller,
      this.placeholder,
      this.inputFormatters,
      this.clearButtonMode = OverlayVisibilityMode.editing,
      this.keyboardType,
      this.obscureText = false,
      this.autocorrect = true,
      this.enableSuggestions = true,
      this.smartDashesType,
      this.smartQuotesType,
      this.autofocus = false,
      this.autofillHints,
      this.onChanged,
      this.textFieldPadding = const EdgeInsets.only(top: 12, bottom: 0),
      this.bottomLineColor = const Color(0xFFB7BDCB),
      this.maxLength})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 22,
            child: Text(title),
          ),
          CupertinoTextField.borderless(
            controller: controller,
            padding: textFieldPadding,
            placeholder: placeholder,
            placeholderStyle: Themes.fontSize14FontWeight400.copyWith(
              color: const Color(0xFFB7BDCB),
            ),
            textAlign: TextAlign.left,
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
            clearButtonMode: clearButtonMode,
          ),
          const Spacer(),
          HorizontalLineWidget(
            color: bottomLineColor,
          ),
        ],
      ),
    );
  }
}
