# Image Classification Demo

Demo application that uses TensorFlow Lite with Android and iOS to do image classification.

The application features:
- A Gauge Chart showing matches
- Taking photos with both front- and back-camera
- Sharing picture
- English and Japanese using the standard Flutter app localization library.

## Getting Started

This github does not host the pre-trained Tensorflow Lite binaries.
You can find the ones used here from [tensorflow.org](https://www.tensorflow.org/lite/guide/hosted_models).

By default, you need to download below assets and put them into the /assets folder:
- mobilenet_v1_1.0_224.txt
- mobilenet_v1_1.0_224.tflite
However, the code does not explicitly use the assets.
You can easily replace the file with any model you trained yourself.
Note that you need to update the pubspec.yaml file to bundle the assets.

To run the application, you can connect an external device or emulator and run main.dart against it.
You will need the additional command line argument `--no-sound-null-safety` since this package depend on some libraries that do no support null safety.

For help getting started with Flutter, view below link:
[online documentation](https://flutter.dev/docs)

## Authors

* **Krister S Jakobsson** - *Implementation* - krister.s.jakobsson@gmail.com

## License

This project is licensed under the Boost License - see the [license](LICENSE.md) file for details
