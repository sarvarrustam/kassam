import 'package:flutter/material.dart';
import 'package:kassam/data/services/api_service.dart';

class GlobalHttpInspectorButton extends StatefulWidget {
  const GlobalHttpInspectorButton({super.key});

  @override
  State<GlobalHttpInspectorButton> createState() =>
      _GlobalHttpInspectorButtonState();
}

class _GlobalHttpInspectorButtonState
    extends State<GlobalHttpInspectorButton> {
  double _xPosition = 20;
  double _yPosition = 100;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _xPosition = (_xPosition + details.delta.dx).clamp(0, screenWidth - 56);
            _yPosition = (_yPosition + details.delta.dy).clamp(0, screenHeight - 56);
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade400,
                Colors.deepOrange.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ApiService.alice.showInspector();
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Text(
                  'HTTP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
