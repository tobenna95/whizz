import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:restart_app/restart_app.dart';
import 'dart:async';


void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whizz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SpeechScreen(),
    );
  }
}


class SpeechScreen extends StatefulWidget {

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  GoogleTranslator translator = GoogleTranslator();
  FlutterTts tts = FlutterTts();


  String langCode = "";

  translate() async{
    await translator.translate(_text, to: langCode).then((output) {
      setState(() {
        _text = output.toString();
      });
    });
  }

  speak() async{
    await tts.setLanguage(langCode);
    await tts.setPitch(1.0);
    await tts.speak(_text);
  }

  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 32.0,
      ),
    ),
  };

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  getLocation() async{
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    permission = await Geolocator.requestPermission();
    if( permission== LocationPermission.denied){
      //nothing
    }
    Position position = await Geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    print(position.latitude);
    print(position.longitude);
    print(placemarks[0].locality.toString());
  }

  @override
  void initState() {
    _speech = stt.SpeechToText();
    getLocation();
    initialListen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Whizz!'),
        leading: GestureDetector(
          onDoubleTap: () {
                Restart.restartApp();
              },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        duration: const Duration(milliseconds: 200),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              onPressed: _listen,
              child: Icon(_isListening ? Icons.mic: Icons.mic_none),
            ),
            FloatingActionButton(
              onPressed: (){
                translate();
                Future.delayed(Duration(minutes: 0, milliseconds: 800), (){
                  speak();
                });
              },
              child: Icon(Icons.translate),
            ),
            // FloatingActionButton(
            //   onPressed: () {
            //     Restart.restartApp();
            //   },
            //   child: Icon(Icons.cancel),
            // ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: TextHighlight(
            text: _text,
            words: _highlights,
            textStyle: const TextStyle(
              fontSize: 32.0,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }



  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Determine the current position of the device.

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }


    return await Geolocator.getCurrentPosition();
  }

  bool listening1 = false;

  initialListen() async {
    if (!listening1) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => listening1 = true);
        _speech.listen(
          listenFor: Duration(seconds: 40),
          onResult: (val) =>
              setState(() {
                _text = val.recognizedWords;
                if (_text.contains("Bien") || _text.contains("Hola") || _text.contains("Buenos dias") || _text.contains("buenos dias") || _text.contains("buenos noches")) {
                  setState((){langCode = "es";
                  print(langCode);});
                }
                else if (_text.contains("bonjour") || _text.contains("Bonjour") || _text.contains("Bonsoir") || _text.contains("bonsoir")) {
                  setState((){langCode = "fr";
                  print(langCode);});
                }  else if (_text.contains("Obrigado")) {
                  setState(() {
                    langCode = "pt";
                    print(langCode);
                  });
                }else {
                  setState((){langCode = "en";
                  print(langCode);});
                }
                if (val.hasConfidenceRating && val.confidence > 0) {
                  _confidence = val.confidence;
                }
              }),
        );
      }
      else {
        setState(() => listening1 = false);
        _speech.stop();
      }
    }
  }



}


