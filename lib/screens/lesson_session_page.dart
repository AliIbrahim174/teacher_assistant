import 'package:flutter/material.dart';

class LessonSessionPage extends StatefulWidget {
  const LessonSessionPage({
    super.key,
  });

  @override
  State<LessonSessionPage> createState() =>
      _LessonSessionPageState();
}


class _LessonSessionPageState
    extends State<LessonSessionPage> {

  String status =
      'جاهز لبدء الحصة';


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'الحصة الحالية',
        ),
        centerTitle: true,
      ),


      body: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),


            const SizedBox(height: 40),


            ElevatedButton.icon(
              onPressed: () {

                setState(() {
                  status =
                      'جاري تشغيل Zoom...';
                });

              },

              icon:
                  const Icon(
                    Icons.video_call,
                  ),

              label:
                  const Text(
                    'بدء الاجتماع',
                  ),
            ),


            const SizedBox(height: 20),


            ElevatedButton.icon(
              onPressed: () {},

              icon:
                  const Icon(
                    Icons.draw,
                  ),

              label:
                  const Text(
                    'فتح لوحة الشرح',
                  ),
            ),


            const SizedBox(height: 20),


            ElevatedButton.icon(
              onPressed: () {},

              icon:
                  const Icon(
                    Icons.stop_circle,
                  ),

              label:
                  const Text(
                    'إنهاء الحصة',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}