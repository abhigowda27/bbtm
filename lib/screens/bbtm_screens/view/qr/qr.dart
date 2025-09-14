import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:bbtml_new/theme/app_colors_extension.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:open_settings/open_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/wifi.dart';
import '../../widgets/custom/custom_button.dart';

class QRPage extends StatefulWidget {
  final String data;
  final String name;
  const QRPage({required this.data, required this.name, super.key});

  @override
  State<QRPage> createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  GlobalKey globalKey = GlobalKey();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late NetworkService _networkService;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.data);
    _networkService = NetworkService();
    _initNetworkInfo();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  String _connectionStatus = 'Unknown';
  Future<void> _updateConnectionStatus(
          List<ConnectivityResult> results) async =>
      _initNetworkInfo();

  Future<void> _initNetworkInfo() async {
    String? wifiName = await _networkService.initNetworkInfo();
    setState(() => _connectionStatus = wifiName ?? "Unknown");
  }

  Future<void> convertQrCodeToImage(
      BuildContext context, String data, String name) async {
    final boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    // Render QR code in a RepaintBoundary
    ui.Image qrImage = await boundary.toImage(pixelRatio: 3);

    // Define margin size and other drawing properties
    const double margin = 20.0;
    const double logoSize = 120.0; // Size of the logo
    const double textSize =
        40.0; // Adjust size based on the text height you expect

    // Calculate image size with margins
    final double qrImageWidth = qrImage.width.toDouble();
    final double qrImageHeight = qrImage.height.toDouble();
    final double imageWidth = qrImageWidth + 2 * margin;
    final double imageHeight =
        qrImageHeight + 3 * margin + logoSize + textSize; // Adjusted height

    // Create a new image with the margins
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, imageWidth, imageHeight));

    // Draw the QR code with margins
    canvas.drawRect(Rect.fromLTWH(0, 0, imageWidth, imageHeight),
        Paint()..color = Colors.white);
    canvas.drawImageRect(
      qrImage,
      Rect.fromLTWH(0, 0, qrImageWidth, qrImageHeight),
      Rect.fromLTWH(margin, margin + logoSize + textSize + margin, qrImageWidth,
          qrImageHeight),
      Paint(),
    );

    // Draw the logo (assuming it's an asset) at the top center
    const logoImage = AssetImage('assets/images/BBT_Logo_2.png');
    final logo = await _loadImage(logoImage);
    final logoRect = Rect.fromLTWH(
      (imageWidth - logoSize) / 2, // Centered horizontally
      margin, // Positioned at the top with margin
      logoSize,
      logoSize,
    );
    canvas.drawImageRect(
      logo,
      Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
      logoRect,
      Paint(),
    );

    // Draw the name below the logo
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 50,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: imageWidth,
    );

    final textOffset = Offset(
      (imageWidth - textPainter.width) / 2,
      logoRect.bottom + 5,
    );

    textPainter.paint(canvas, textOffset);

    // End recording and create the image
    ui.Image finalImage = await recorder
        .endRecording()
        .toImage(imageWidth.toInt(), imageHeight.toInt());

    // Convert the image to PNG format
    ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    final directory = (await getTemporaryDirectory()).path;
    File imgFile = File("$directory/qrCode.png");
    await imgFile.writeAsBytes(pngBytes);

    // Share the image
    await Share.shareFiles([imgFile.path],
        text:
            "Enjoy the ease of controlling your switches effortless operation, happy living!");
  }

  Future<ui.Image> _loadImage(ImageProvider provider) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final ImageStreamListener listener =
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
      completer.complete(info.image);
    });
    stream.addListener(listener);
    return completer.future;
  }

  Future _shareQRImage() async {
    final image = await QrPainter(
      data: widget.data,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.white,
    ).toImageData(200.0, format: ImageByteFormat.png);
    const filename = 'qr_code.png';
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$filename').create();
    var bytes = image!.buffer.asUint8List();
    await file.writeAsBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR CODE ")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              RepaintBoundary(
                key: globalKey,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: widget.data,
                      backgroundColor: Theme.of(context).appColors.background,
                      version: QrVersions.auto,
                      gapless: true,
                      foregroundColor: Theme.of(context).appColors.textPrimary,
                      size: 200.0,
                    ),
                    // Positioned(
                    //   bottom: 10,
                    //   child: Container(
                    //     color: Colors.white.withOpacity(0.8),
                    //     padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    //     child: Text(
                    //       widget.name,
                    //       style: const TextStyle(
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 16,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  convertQrCodeToImage(context, widget.data, widget.name);
                },
                child: Text(
                  "Share",
                  style:
                      TextStyle(color: Theme.of(context).appColors.background),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'WIFI is connected to Wifi Name',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '"$_connectionStatus"',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(color: Theme.of(context).appColors.primary),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                text: "Open WIFI Settings",
                icon: Icons.wifi_find,
                onPressed: () {
                  OpenSettings.openWIFISetting();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
