
import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClear;
  final String initialText;

  const SearchBarWidget({
    required this.onSearch,
    required this.onClear,
    required this.initialText,
  });

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialText;
    _controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm đơn hàng, khách hàng...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15.0,
            vertical: 10.0,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _controller.clear();
                        widget.onClear();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () => widget.onSearch(_controller.text),
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}