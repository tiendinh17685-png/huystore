import 'package:flutter/material.dart';

 
class QuantityInput extends StatefulWidget {
  final int initialQuantity;
  final ValueChanged<int> onChanged;

  const QuantityInput(
      {super.key, required this.initialQuantity, required this.onChanged});

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment() {
    setState(() {
      _quantity++;
      widget.onChanged(_quantity);
    });
  }

  void _decrement() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        widget.onChanged(_quantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 28, 
            child: IconButton(
              icon: const Icon(Icons.remove, size: 14), 
              onPressed: _decrement,
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            width: 25,
            child: Text(
              _quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 20,
            height: 28, 
            child: IconButton(
              icon: const Icon(Icons.add, size: 14), 
              onPressed: _increment,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}