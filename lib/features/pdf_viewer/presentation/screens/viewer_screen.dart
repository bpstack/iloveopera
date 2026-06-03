import 'package:flutter/material.dart';

class ViewerScreen extends StatelessWidget {
  const ViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('iloveopera'),
      ),
      body: Center(
        child: Text(
          'Aquí irá el visor PDF',
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
