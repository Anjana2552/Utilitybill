import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class UtilityPaymentPlaceholder extends StatelessWidget {
  const UtilityPaymentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CurvedHeaderPage(
      title: 'Payments',
      headerHeight: 200,
      titleAlignment: HeaderTitleAlignment.left,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Utility payments are managed by consumers. ',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              'As a utility provider, you can generate bills and view user lists, but payment collection happens from the user app side.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
