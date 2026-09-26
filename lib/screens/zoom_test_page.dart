import 'package:flutter/material.dart';

import '../services/zoom_service.dart';

class ZoomTestPage extends StatefulWidget {
  const ZoomTestPage({super.key});

  @override
  State<ZoomTestPage> createState() => _ZoomTestPageState();
}

class _ZoomTestPageState extends State<ZoomTestPage> {
  String status = 'لم يتم الاختبار بعد';

  Future<void> _checkZoom() async {
    setState(() {
      status = 'جاري تهيئة Zoom...';
    });

    final initializeResult = await ZoomService.instance.initialize();

    final initialized = initializeResult['success'] == true;
    final errorCode = initializeResult['errorCode'] ?? '-';

    final internalError = initializeResult['internalErrorCode'] ?? '-';
    final available = await ZoomService.instance.isAvailable();

    final ready = await ZoomService.instance.isInitialized();

    if (!mounted) return;

    setState(() {
      status =
          '''
Zoom SDK موجود: ${available ? 'نعم' : 'لا'}

طلب التهيئة:
${initialized ? 'نجح' : 'فشل'}

Error Code:
$errorCode

Internal Error:
$internalError
حالة Zoom:
${ready ? 'جاهز' : 'غير جاهز'}
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار Zoom')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _checkZoom,
              child: const Text('فحص Zoom SDK'),
            ),
          ],
        ),
      ),
    );
  }
}
