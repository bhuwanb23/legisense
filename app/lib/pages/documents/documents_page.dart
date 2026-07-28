import 'package:flutter/material.dart';

import '../../widgets/home/stub_scaffold.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StubScaffold(
      title: 'My Documents',
      subtitle:
          'Full history connects when the backend is ready. Recent analyses stay on Home for now.',
    );
  }
}
