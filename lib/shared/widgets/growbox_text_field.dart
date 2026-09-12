import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Major email providers offered as completions once the user types '@'.
const _kEmailDomains = [
  'gmail.com',
  'yahoo.com',
  'outlook.com',
  'hotmail.com',
  'icloud.com',
  'proton.me',
];

class GrowboxTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  /// When true, typing '@' in the field surfaces tappable chips for common
  /// email domains (gmail.com, yahoo.com, ...) that complete the address.
  final bool suggestEmailDomains;

  /// Optional external focus node. One is created internally when
  /// [suggestEmailDomains] is enabled and none is supplied.
  final FocusNode? focusNode;

  /// Whether the field should grab focus on first build.
  final bool autofocus;

  const GrowboxTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.suggestEmailDomains = false,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<GrowboxTextField> createState() => _GrowboxTextFieldState();
}

class _GrowboxTextFieldState extends State<GrowboxTextField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode? get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  @override
  void didUpdateWidget(covariant GrowboxTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suggestEmailDomains != oldWidget.suggestEmailDomains) {
      _attachListeners();
    }
  }

  void _attachListeners() {
    if (widget.suggestEmailDomains) {
      // Ensures an internal focus node exists to track focus for the chips.
      _internalFocusNode ??= FocusNode();
      _controller.addListener(_refreshSuggestions);
      _internalFocusNode!.addListener(_refreshSuggestions);
    } else {
      _controller.removeListener(_refreshSuggestions);
      _internalFocusNode?.removeListener(_refreshSuggestions);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshSuggestions);
    _internalFocusNode?.removeListener(_refreshSuggestions);
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _refreshSuggestions() {
    if (mounted) setState(() {});
  }

  /// Domains to offer right now: only while the field is focused and the
  /// text ends with '@' (or a partial domain after it).
  List<String> get _domainSuggestions {
    if (!widget.suggestEmailDomains) return const [];
    if (!(_effectiveFocusNode?.hasFocus ?? false)) return const [];
    final text = _controller.text;
    final at = text.lastIndexOf('@');
    if (at < 0) return const [];
    final domainPart = text.substring(at + 1);
    if (domainPart.isEmpty) return _kEmailDomains.take(4).toList();
    if (domainPart.contains(RegExp(r'[\s@]'))) return const [];
    final query = domainPart.toLowerCase();
    return _kEmailDomains
        .where((d) => d != query && d.startsWith(query))
        .take(4)
        .toList();
  }

  void _applyDomain(String domain) {
    final text = _controller.text;
    final at = text.lastIndexOf('@');
    if (at < 0) return;
    final newValue = '${text.substring(0, at + 1)}$domain';
    _controller.value = TextEditingValue(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
    );
    _effectiveFocusNode?.requestFocus();
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suggestions = _domainSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controller,
          focusNode: _effectiveFocusNode,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefix,
            suffixIcon: widget.suffix,
            errorText: widget.errorText,
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final domain in suggestions) _domainChip(domain, isDark),
            ],
          ),
        ],
      ],
    );
  }

  Widget _domainChip(String domain, bool isDark) {
    return InkWell(
      onTap: () => _applyDomain(domain),
      // Must NOT take focus on press: stealing it from the email field
      // blurs the field, which unmounts these chips mid-tap and the
      // selection never lands.
      canRequestFocus: false,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Text(
          '@$domain',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
