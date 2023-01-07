import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ktemplate/app/common/color_utils.dart';



typedef ValidatorT = String? Function(String?);

class InputField extends StatefulWidget {
  final bool isReadOnly;
  final int? maxLength;
  final int? maxLines;
  final TextStyle? textStyle;
  final String? hintText;
  final String? labelText;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final bool roundBox;
  final int? roundBoxRadius;
  final bool obscureText;
  final TextEditingController? controller;
  final ValidatorT? validator;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputType? keyboardType;
  final Function? onFieldSubmitted;
  final RegExp? formatter;
  final Future<bool> Function()? getVCode;

  const InputField({
    Key? key,
    this.isReadOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.textStyle,
    this.hintText = "",
    this.labelText,
    this.hintStyle,
    this.padding,
    this.borderColor,
    this.prefixIcon,
    this.suffixIcon,
    this.getVCode,
    this.autofocus = false,
    this.obscureText = false,
    this.roundBox = false, 
    this.roundBoxRadius, 
    this.controller,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    this.formatter,
    this.onFieldSubmitted,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<InputField> {
  /// 倒计时秒数
  bool _isClick = true;
  final int second = 20;

  /// 当前秒数
  int currentSecond = 0;
  StreamSubscription? _obs;

  fieldFocusChange(BuildContext context, FocusNode? currentFocus, FocusNode? nextFocus) {
    currentFocus!.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  _getVCode() async {
    bool isSuccess = await widget.getVCode!();
    if (isSuccess) {
      setState(() {
        currentSecond = second;
        _isClick = false;
      });
      _obs = Stream.periodic(Duration(seconds: 1), (i) => i).take(second).listen((i) {
        setState(() {
          currentSecond = second - i - 1;
          _isClick = currentSecond < 1;
        });
      });
    }
  }

  @override
  void dispose() {
    _obs?.cancel();
    super.dispose();
  }

  Widget _createTextField() {
    List<TextInputFormatter> textInputFormatter;
    if (null == widget.formatter) {
      if (widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone) {
        textInputFormatter = [FilteringTextInputFormatter.allow(RegExp("[0-9]"))];
      } else {
        textInputFormatter = [];
      }
    } else {
      textInputFormatter = [FilteringTextInputFormatter.allow(widget.formatter ?? '')];
    }

    return TextFormField(
      readOnly: widget.isReadOnly,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      controller: widget.controller,
      validator: widget.validator,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onFieldSubmitted: widget.nextFocusNode != null
          ? (_) => fieldFocusChange(
                context,
                widget.focusNode,
                widget.nextFocusNode,
              )
          : (_) => widget.focusNode!.unfocus(),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      inputFormatters: textInputFormatter,
      style: widget.textStyle,
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.labelText,
        // contentPadding: EdgeInsets.only(
        //   top: 5,
        //   bottom: 5,
        // ),
        border: InputBorder.none,
        fillColor: HexToColor("#482C70"),
        // 如果filled=true，则背景为fillColor，无需包在Container控件中
        // filled: false,
        // errorText: 'error',
        //计算数字
        counterText: "",
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BuildTextfieldWrapper(
      _createTextField(),
      widget,
      _isClick,
      getVCodeCallback: _getVCode,
      second: currentSecond.toString(),
    );
  }
}

class BuildTextfieldWrapper extends StatelessWidget {
  final Widget child;
  final widget;
  final bool _isClick;
  final Function? getVCodeCallback;
  final String? second;
  BuildTextfieldWrapper(this.child, this.widget, this._isClick, {this.getVCodeCallback, this.second});

  @override
  Widget build(BuildContext context) {
    Decoration _decoration = widget.roundBox
        ? BoxDecoration(
            border: Border.all(
              width: 1,
              color: widget.borderColor ?? Color.fromRGBO(217, 217, 217, 1),
            ),
            borderRadius: widget.roundBoxRadius == 0
                ? BorderRadius.zero
                : BorderRadius.all(Radius.circular(widget.roundBoxRadius ?? 32)),
          )
        : UnderlineTabIndicator(
            borderSide: BorderSide(width: 1.0, color: Colors.black),
          );

    EdgeInsetsGeometry _padding = widget.padding ?? EdgeInsets.fromLTRB(16, 0, 16, 0);

    return Container(
      padding: _padding,
      decoration: _decoration,
      child: Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          null == widget.prefixIcon ? empty : widget.prefixIcon,
          null == widget.prefixIcon ? empty : hGap10,
          Expanded(
            flex: 80,
            child: child,
          ),
          null == widget.suffixIcon ? SizedBox : widget.suffixIcon,
          null == widget.suffixIcon ? empty : hGap10,
          widget.getVCode == null
              ?empty
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    SizedBox(width: 16),
                    SizedBox(
                      width: 1,
                      height: 24,
                      child: Container(
                        color: HexToColor('#767680'),
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      // padding: EdgeInsets.symmetric(vertical: 0),
                      onTap: _isClick ? getVCodeCallback!() : null,
                      // padding: EdgeInsets.symmetric(vertical: 0),
                      child: Text(
                        _isClick ? "获取验证码" : "$second秒后重发",
                        style: TextStyle(color: HexToColor('#A061FD')),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
    static final Widget hGap10 = SizedBox(width: 10);
  static Widget empty = SizedBox();

}
