import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';

class CustomPage extends StatefulWidget {
  const CustomPage({super.key});

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  final _controller = DocumentScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DocumentScanner(
        controller: _controller,
        generalStyles: const GeneralStyles(
          hideDefaultBottomNavigation: true,
          messageTakingPicture: '处理中请稍后',
          messageCroppingPicture: '裁剪中请稍后',
          messageEditingPicture: '处理中请稍后',
          messageSavingPicture: '保存图片中请稍后',
          baseColor: Colors.teal,
        ),
        takePhotoDocumentStyle: TakePhotoDocumentStyle(
          top: MediaQuery.of(context).padding.top + 25,
          hideDefaultButtonTakePicture: true,
          onLoading: const CircularProgressIndicator(
            color: Colors.white,
          ),
          children: [
            // * AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.teal,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 15,
                ),
                child: const Center(
                  child: Text(
                    '拍摄文稿内容',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),

            // * Button to take picture
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _controller.takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Text(
                    '拍摄',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        cropPhotoDocumentStyle: CropPhotoDocumentStyle(
          top: MediaQuery.of(context).padding.top,
          maskColor: Colors.teal.withOpacity(0.2),
          textButtonSave: '确定',
        ),
        editPhotoDocumentStyle: EditPhotoDocumentStyle(
          top: MediaQuery.of(context).padding.top,
          textButtonSave: '保存',
          textButtonEco: '扫描',
          textButtonGray: '黑白',
          textButtonNatural: '原色',
        ),
        resolutionCamera: ResolutionPreset.ultraHigh,
        pageTransitionBuilder: (child, animation) {
          final tween = Tween<double>(begin: 0, end: 1);

          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return ScaleTransition(
            scale: tween.animate(curvedAnimation),
            child: child,
          );
        },
        onSave: (Uint8List imageBytes) {
          // ? Bytes of the document/image already processed
        },
      ),
    );
  }
}
