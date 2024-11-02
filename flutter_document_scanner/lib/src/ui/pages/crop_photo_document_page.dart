// Copyright (c) 2021, Christian Betancourt
// https://github.com/criistian14
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/app/app_event.dart';
import 'package:flutter_document_scanner/src/bloc/crop/crop_bloc.dart';
import 'package:flutter_document_scanner/src/bloc/crop/crop_event.dart';
import 'package:flutter_document_scanner/src/bloc/crop/crop_state.dart';
import 'package:flutter_document_scanner/src/ui/widgets/app_bar_crop_photo.dart';
import 'package:flutter_document_scanner/src/ui/widgets/mask_crop.dart';
import 'package:flutter_document_scanner/src/utils/border_crop_area_painter.dart';
import 'package:flutter_document_scanner/src/utils/dot_utils.dart';
import 'package:flutter_document_scanner/src/utils/image_utils.dart';

/// Page to crop a photo
class CropPhotoDocumentPage extends StatelessWidget {
  /// Create a page with style
  const CropPhotoDocumentPage({
    super.key,
    required this.cropPhotoDocumentStyle,
  });

  /// Style of the page
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false, // When false, blocks the current route from being popped.
      onPopInvokedWithResult: (bool didPop, Object? result) {
        _onPop(context);
      },
      // onWillPop: () => _onPop(context),
      child: BlocSelector<AppBloc, AppState, File?>(
        selector: (state) => state.pictureInitial,
        builder: (context, state) {
          if (state == null) {
            return const Center(
              child: Text('NO IMAGE'),
            );
          }

          return BlocProvider(
            create: (context) => CropBloc(
              dotUtils: DotUtils(
                minDistanceDots: cropPhotoDocumentStyle.minDistanceDots,
              ),
              imageUtils: ImageUtils(),
            )..add(
                CropAreaInitialized(
                  areaInitial: context.read<AppBloc>().state.contourInitial,
                  defaultAreaInitial: cropPhotoDocumentStyle.defaultAreaInitial,
                  image: state,
                  screenSize: screenSize,
                  positionImage: Rect.fromLTRB(
                    cropPhotoDocumentStyle.left,
                    cropPhotoDocumentStyle.top,
                    cropPhotoDocumentStyle.right,
                    cropPhotoDocumentStyle.bottom,
                  ),
                ),
              ),
            child: _CropView(
              cropPhotoDocumentStyle: cropPhotoDocumentStyle,
              image: state,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _onPop(BuildContext context) async {
    await context
        .read<DocumentScannerController>()
        .changePage(AppPages.takePhoto);
    return false;
  }
}

class _CropView extends StatefulWidget {
  const _CropView({
    required this.cropPhotoDocumentStyle,
    required this.image,
  });
  final CropPhotoDocumentStyle cropPhotoDocumentStyle;
  final File image;

  @override
  __CropView createState() => __CropView();
}

class __CropView extends State<_CropView> {

  late CropPhotoDocumentStyle cropPhotoDocumentStyle;
  late File image;
  Point maginifierRefPoint = const Point(0, 0);

  @override
  void initState() {
    super.initState();
    cropPhotoDocumentStyle = widget.cropPhotoDocumentStyle;
    image = widget.image;
  }

  // 隐藏圆角
  int leftTopPointOpacity = 1;
  int leftBottomPointOpacity = 1;
  int rightTopPointOpacity = 1;
  int rightBottomPointOpacity = 1;
  int magnifierOpacity = 0;
  

  @override
  Widget build(BuildContext context) {

    // 调整边用的个数
    const int borderHeightCount = 2;

    // 放大镜的大小
    const int magnifierSize = 100;

    // 放大镜的顶端距离
    const int maginifierDxTop = 20;

    return MultiBlocListener(
      listeners: [
        BlocListener<AppBloc, AppState>(
          listenWhen: (previous, current) =>
              current.statusCropPhoto != previous.statusCropPhoto,
          listener: (context, state) {
            if (state.statusCropPhoto == AppStatus.loading) {
              context.read<CropBloc>().add(CropPhotoByAreaCropped(image));
            }
          },
        ),
        BlocListener<CropBloc, CropState>(
          listenWhen: (previous, current) =>
              current.imageCropped != previous.imageCropped,
          listener: (context, state) {
            if (state.imageCropped != null) {
              context.read<AppBloc>().add(
                    AppLoadCroppedPhoto(
                      image: state.imageCropped!,
                      area: state.areaParsed!,
                    ),
                  );
            }
          },
        ),
      ],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: cropPhotoDocumentStyle.top,
            bottom: cropPhotoDocumentStyle.bottom,
            left: cropPhotoDocumentStyle.left,
            right: cropPhotoDocumentStyle.right,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // * Photo
                Positioned.fill(
                  child: Image.file(
                    image,
                    fit: BoxFit.fill,
                  ),
                ),

                // * Mask
                BlocSelector<CropBloc, CropState, Area>(
                  selector: (state) => state.area,
                  builder: (context, state) {
                    return MaskCrop(
                      area: state,
                      cropPhotoDocumentStyle: cropPhotoDocumentStyle,
                    );
                  },
                ),

                // * 线框
                BlocSelector<CropBloc, CropState, Area>(
                  selector: (state) => state.area,
                  builder: (context, state) {
                    return CustomPaint(
                      painter: BorderCropAreaPainter(
                        area: state,
                        colorBorderArea: cropPhotoDocumentStyle.colorBorderArea,
                        widthBorderArea: cropPhotoDocumentStyle.widthBorderArea,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),

                // * Dot - All
                BlocSelector<CropBloc, CropState, Area>(
                  selector: (state) => state.area,
                  builder: (context, state) {
                    return GestureDetector(
                      onPanUpdate: (details) {
                        context.read<CropBloc>().add(
                              CropDotMoved(
                                deltaX: details.delta.dx,
                                deltaY: details.delta.dy,
                                dotPosition: DotPosition.all,
                              ),
                            );
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: state.topLeft.x + state.topRight.x,
                        height: state.topLeft.y + state.topRight.y,
                      ),
                    );
                  },
                ),

                // * Dot - Top Left
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) => state.area.topLeft,
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                            CropDotMoved(
                              deltaX: details.delta.dx,
                              deltaY: details.delta.dy,
                              dotPosition: DotPosition.topLeft,
                            ),
                          );
                          maginifierRefPoint = Point(state.x, state.y);
                        },
                        onPanStart: (details) {
                          maginifierRefPoint = Point(state.x, state.y);
                          setState(() {
                            leftTopPointOpacity = 0;
                            magnifierOpacity = 1;
                          });
                        },
                        onPanEnd: (details) {
                          maginifierRefPoint = const Point(0,0);
                          setState(() {
                            leftTopPointOpacity = 1;
                            magnifierOpacity = 0;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Opacity(
                                opacity: leftTopPointOpacity.toDouble(),
                                child: Container(
                                  width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // * Dot - Top Right
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) => state.area.topRight,
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                            CropDotMoved(
                              deltaX: details.delta.dx,
                              deltaY: details.delta.dy,
                              dotPosition: DotPosition.topRight,
                            ),
                          );
                          maginifierRefPoint = Point(state.x, state.y);
                        },
                        onPanStart: (details) {
                          maginifierRefPoint = Point(state.x, state.y);
                          setState(() {
                            rightTopPointOpacity = 0;
                            magnifierOpacity = 1;
                          });
                        },
                        onPanEnd: (details) {
                          maginifierRefPoint = const Point(0,0);
                          setState(() {
                            rightTopPointOpacity = 1;
                            magnifierOpacity = 0;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Opacity(
                                opacity: rightTopPointOpacity.toDouble(),
                                child: Container(
                                  width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // * Dot - Bottom Left
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) => state.area.bottomLeft,
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                            CropDotMoved(
                              deltaX: details.delta.dx,
                              deltaY: details.delta.dy,
                              dotPosition: DotPosition.bottomLeft,
                            ),
                          );
                          maginifierRefPoint = Point(state.x, state.y);
                        },
                        onPanStart: (details) {
                          maginifierRefPoint = Point(state.x, state.y);
                          setState(() {
                            leftBottomPointOpacity = 0;
                            magnifierOpacity = 1;
                          });
                        },
                        onPanEnd: (details) {
                          maginifierRefPoint = const Point(0,0);
                          setState(() {
                            leftBottomPointOpacity = 1;
                            magnifierOpacity = 0;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Opacity(
                                opacity: leftBottomPointOpacity.toDouble(),
                                child: Container(
                                  width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // * Dot - Bottom Right
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) => state.area.bottomRight,
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                            CropDotMoved(
                              deltaX: details.delta.dx,
                              deltaY: details.delta.dy,
                              dotPosition: DotPosition.bottomRight,
                            ),
                          );
                          maginifierRefPoint = Point(state.x, state.y);
                        },
                        onPanStart: (details) {
                          maginifierRefPoint = Point(state.x, state.y);
                          setState(() {
                            rightBottomPointOpacity = 0;
                            magnifierOpacity = 1;
                          });
                        },
                        onPanEnd: (details) {
                          maginifierRefPoint = const Point(0,0);
                          setState(() {
                            rightBottomPointOpacity = 1;
                            magnifierOpacity = 0;
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Opacity(
                                opacity: rightBottomPointOpacity.toDouble(),
                                child: Container(
                                  width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 左边的线中段
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) {
                    return Point((state.area.topLeft.x + state.area.bottomLeft.x)/ 2.0, (state.area.topLeft.y + state.area.bottomLeft.y) / 2.0);
                  },
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize * borderHeightCount / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.topLeft,
                                ),
                              );
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.bottomLeft,
                                ),
                              );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize * borderHeightCount,
                          child: Transform.rotate(
                            angle: pi/3,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  cropPhotoDocumentStyle.dotRadius,
                                ),
                                child: Container(
                                  width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                  height:
                                      cropPhotoDocumentStyle.dotSize * borderHeightCount - (2 * 2),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 上边的线中段
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) {
                    return Point((state.area.topLeft.x + state.area.topRight.x)/ 2.0, (state.area.topLeft.y + state.area.topRight.y) / 2.0);
                  },
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize * borderHeightCount / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.topLeft,
                                ),
                              );
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.topRight,
                                ),
                              );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize * borderHeightCount,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Container(
                                width: cropPhotoDocumentStyle.dotSize * borderHeightCount - (2 * 2),
                                height:
                                    cropPhotoDocumentStyle.dotSize - (2 * 2),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 右边的线中段
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) {
                    return Point((state.area.topRight.x + state.area.bottomRight.x)/ 2.0, 
                                (state.area.topRight.y + state.area.bottomRight.y) / 2.0,);
                  },
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize * borderHeightCount / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.topRight,
                                ),
                              );
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.bottomRight,
                                ),
                              );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize,
                          height: cropPhotoDocumentStyle.dotSize * borderHeightCount,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Container(
                                width: cropPhotoDocumentStyle.dotSize - (2 * 2),
                                height:
                                    cropPhotoDocumentStyle.dotSize * borderHeightCount - (2 * 2),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 下边的线中段
                BlocSelector<CropBloc, CropState, Point>(
                  selector: (state) {
                    return Point((state.area.bottomLeft.x + state.area.bottomRight.x)/ 2.0, 
                                  (state.area.bottomLeft.y + state.area.bottomRight.y) / 2.0,);
                  },
                  builder: (context, state) {
                    return Positioned(
                      left: state.x - (cropPhotoDocumentStyle.dotSize * borderHeightCount / 2),
                      top: state.y - (cropPhotoDocumentStyle.dotSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.bottomLeft,
                                ),
                              );
                          context.read<CropBloc>().add(
                                CropDotMoved(
                                  deltaX: details.delta.dx,
                                  deltaY: details.delta.dy,
                                  dotPosition: DotPosition.bottomRight,
                                ),
                              );
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: cropPhotoDocumentStyle.dotSize * borderHeightCount,
                          height: cropPhotoDocumentStyle.dotSize,
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                cropPhotoDocumentStyle.dotRadius,
                              ),
                              child: Container(
                                width: cropPhotoDocumentStyle.dotSize * borderHeightCount - (2 * 2),
                                height:
                                    cropPhotoDocumentStyle.dotSize - (2 * 2),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 放大镜-左上
                BlocSelector<CropBloc, CropState, Area>(
                  selector: (state) => state.area,
                  builder: (context, state) {
                    return Positioned(
                      left: maginifierRefPoint.x - (magnifierSize / 2),
                      top: (maginifierRefPoint.y - magnifierSize - maginifierDxTop).toDouble(),
                      child: Opacity(
                        opacity: magnifierOpacity.toDouble(),
                        child: RawMagnifier(
                          size: Size(magnifierSize.toDouble(), magnifierSize.toDouble()),
                          focalPointOffset: const Offset(0, magnifierSize / 2 + maginifierDxTop),
                          decoration: const MagnifierDecoration(
                            shape: CircleBorder(
                              side: BorderSide(color: Colors.green, width: 2),
                            ),
                          ),
                          magnificationScale: 2,
                        ),
                      ),
                    );
                  },
                ),


              ],
            ),
          ),

          // * Default App Bar
          AppBarCropPhoto(
            cropPhotoDocumentStyle: cropPhotoDocumentStyle,
          ),

          // * children
          if (cropPhotoDocumentStyle.children != null)
            ...cropPhotoDocumentStyle.children!,
        ],
      ),
    );
  }

}
