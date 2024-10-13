import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

class SocketHandler {
  static const url = "https://shrimp-select-vertically.ngrok-free.app";

  static io.Socket socket = io.io(url,
      OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .build());

}