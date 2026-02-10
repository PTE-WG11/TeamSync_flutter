import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// 通用文本输入框
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool isPassword;
  final bool isSearch;
  final int? maxLines;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final void Function(String)? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.isPassword = false,
    this.isSearch = false,
    this.maxLines = 1,
    this.keyboardType,
    this.controller,
    this.onClear,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isObscured = true;
  bool _isFocused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: AppAnimations.fast,
            style: TextStyle(
              fontSize: 14,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
              color: _isFocused ? AppColors.primary : AppColors.textPrimary,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: AppAnimations.normal,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword && _isObscured,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            validator: widget.validator,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            onFieldSubmitted: widget.onSubmitted,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: widget.enabled ? AppColors.surface : AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              prefixIcon: widget.isSearch
                  ? const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                widget.errorText!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    }

    if (widget.isSearch && widget.controller?.text.isNotEmpty == true) {
      return IconButton(
        icon: const Icon(
          Icons.clear,
          color: AppColors.textSecondary,
          size: 18,
        ),
        onPressed: () {
          widget.controller?.clear();
          widget.onClear?.call();
        },
      );
    }

    return null;
  }
}
