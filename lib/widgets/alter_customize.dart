import 'package:flutter/material.dart';

class AlterCustomizeItem extends StatelessWidget {
  final Map<String, dynamic> alterRequest;

  const AlterCustomizeItem({required this.alterRequest});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: ${alterRequest['category']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Use RichText for colored labels
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: alterRequest.containsKey('design_inspiration')
                        ? 'Design Inspiration: '
                        : 'Description: ',
                    style: TextStyle(
                      color: Colors.red, // Color for the label
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: alterRequest.containsKey('design_inspiration')
                        ? alterRequest['design_inspiration']
                        : alterRequest['description'],
                    style: TextStyle(color: Colors.black), // Default color for the text
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Cost: 150 Rs.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
