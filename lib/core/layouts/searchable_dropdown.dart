import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class SearchableDropdown<T> extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final Future<List<T>> Function(String) suggestionsCallback;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T) onSelected;
  final Widget? suffixIcon;
  final bool autofocus;
  final bool loading;
  final Widget? loadingBuilder;
  final Widget? emptyBuilder;
  final String? Function(T)? onHover;

  const SearchableDropdown({
    super.key,
    required this.labelText,
    required this.controller,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.onSelected,
    this.hintText = '',
    this.suffixIcon,
    this.autofocus = false,
    this.loading = false,
    this.loadingBuilder,
    this.emptyBuilder,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<T>(
      controller: controller,
      builder: (context, controller, focusNode) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
      suggestionsCallback: suggestionsCallback,
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      emptyBuilder: (context) {
        if (loading) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return emptyBuilder ??
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Không tìm thấy.'),
            );
      },
      loadingBuilder: (context) {
        if (loading) {
          return loadingBuilder ??
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
        }
        return const SizedBox.shrink();
      } 
    );
  }
}