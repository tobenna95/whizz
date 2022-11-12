//Packages imported
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

//Main function to run the application
void main() {
  runApp(MyApp());
}

//Stateless class function to build the application
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

//Stateful widget
class SpeechScreen extends StatefulWidget {

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  //Declaration of object for Translation
  GoogleTranslator translator = GoogleTranslator();
  FlutterTts tts = FlutterTts();

  //Declaration of langCode as an empty string
  String langCode = "";

  //Asynchronous function for Translation
  translate() async{
    //Translator object is called to translate input(_text) from listen function
    await translator.translate(_text, to: langCode).then((output) {
      //State is set on the translated input and the output is converted to a string
      setState(() {
        _text = output.toString();
      });
    });
  }

  //Asynchronous function for the Text-to-speech action done on translated text
  //Pitch of the speech is set and the Text-to-Speech package produces the translated speech
  speak() async{
    await tts.setLanguage(langCode);
    await tts.setPitch(1.0);
    await tts.speak(_text);
  }
  //Function for highlighting certain words
  final Map<String, HighlightedWord> _highlights = {
    //When the application encounters the word 'flutter', it will be highlighted
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 32.0,
      ),
    ),
  };

  //Speech to text object declaration
  late stt.SpeechToText _speech;

  //_isListening is initialized to false until the listen app is called
  bool _isListening = false;

  //Placeholder text for the application display box
  String _text = 'Press the button and start speaking';

  //
  double _confidence = 1.0;

  //Asynchronous Function to determine location
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

  //Initialization function for initializing states in the application
  //getLocation, initialListen, _speech are initialized here
  @override
  void initState() {
    _speech = stt.SpeechToText(); // initialization for _speech object
    getLocation(); //getLocation initialized on app launch
    initialListen(); //initialListen initialized on app launch
  }
  //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Whizz!'), //App title bar
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
            FloatingActionButton( //Floating action button for the listen button
              onPressed: _listen,
              child: Icon(_isListening ? Icons.mic: Icons.mic_none),
            ),
            FloatingActionButton( //Floating action button for the translate button
              onPressed: (){
                translate(); //Translate function called to translate input from listen function
                Future.delayed(Duration(minutes: 0, milliseconds: 800), (){ //output delayed for 8 secs to be able to correctly relay the translated text
                  speak(); //Speak function called
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


  // _listen function called when listen button is pressed
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) { //if _listening is available, its state is changed to true and the resultant text is checked with the words in  the "recognized words" library
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;  //resultant text converted from speech checked with the recognized library
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false); //If listening has stopped, _isListening is set as false
      _speech.stop();
    }
  }

  // Asynchronous to determine the current position of the device.
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
  //Asynchronous function to detect keyword
  initialListen() async {
    if (!listening1) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => listening1 = true);
        _speech.listen(
          listenFor: Duration(seconds: 40), //Time added to listen for keyword
          onResult: (val) =>
              setState(() {
                _text = val.recognizedWords;
                //Spanish keywords to be detected
                if (_text.contains("Bien") || _text.contains("Hola") || _text.contains("Buenos dias") || _text.contains("buenos dias") || _text.contains("buenos noches")) {
                  setState((){langCode = "es";
                  print(langCode);});
                }
                //French keywords to be detected
                else if (_text.contains("bonjour") || _text.contains("Bonjour") || _text.contains("Bonsoir") || _text.contains("bonsoir")) {
                  setState((){langCode = "fr";
                  print(langCode);});
                }
                //Portuguese keywords to be detected
                else if (_text.contains("Obrigado")) {
                  setState(() {
                    langCode = "pt";
                    print(langCode);
                  });
                }
                //Default is to English if no keyword detected
                else {
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


