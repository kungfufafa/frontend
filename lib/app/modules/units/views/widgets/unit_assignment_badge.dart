import 'package:flutter/material.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

class UnitAssignmentBadge extends StatelessWidget {
  final Unit? unit;
  final bool isHighlighted;
  
  const UnitAssignmentBadge({
    super.key,
    this.unit,
    this.isHighlighted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (unit == null) {
      return Chip(
        label: const Text(
          'Unassigned',
          style: TextStyle(fontSize: 10),
        ),
        backgroundColor: Colors.grey[200],
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    
    return Chip(
      label: Text(
        unit!.nama,
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: isHighlighted 
        ? Colors.blue[100] 
        : Colors.green[100],
      avatar: Icon(
        Icons.business, 
        size: 14,
        color: isHighlighted 
          ? Colors.blue[700] 
          : Colors.green[700],
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}