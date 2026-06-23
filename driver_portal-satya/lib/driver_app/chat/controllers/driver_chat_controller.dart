import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/socket_service.dart';

class DriverChatController extends GetxController {
  final SocketService socketService = Get.find<SocketService>();
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final messages = <Map<String, dynamic>>[].obs;
  final isTyping = false.obs;
  final otherParticipantRating = "0.0".obs;
  
  late String rideId;
  late String otherParticipantName;
  late String otherParticipantId;
  late String profileImage;
  late String currentUserId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    rideId = args['rideId']?.toString() ?? '';
    otherParticipantName = args['name'] ?? 'Customer';
    otherParticipantId = args['otherId']?.toString() ?? '';
    profileImage = args['profileImage']?.toString() ?? '';
    otherParticipantRating.value = (args['rating'] ?? "0.0").toString();
    
    _initChat();
  }

  void _initChat() async {
    currentUserId = await ApiService.getDriverId() ?? '';
    
    // Join ride room
    socketService.socket?.emit('ride:join', rideId);
    
    // Listen for messages
    socketService.socket?.on('message:receive', (data) {
      messages.add(data);
      _scrollToBottom();
    });

    // Listen for typing
    socketService.socket?.on('chat:typing', (data) {
      if (data['senderId'] == otherParticipantId) {
        isTyping.value = data['isTyping'];
      }
    });

    // Fetch history
    _fetchHistory();
  }

  void _fetchHistory() async {
    try {
      final List history = await ApiService.getMessages(rideId);
      messages.assignAll(history.map((m) => m as Map<String, dynamic>).toList());
      _scrollToBottom();
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final data = {
      'rideId': rideId,
      'senderId': currentUserId,
      'senderType': 'Driver',
      'text': text
    };

    socketService.socket?.emit('message:send', data);
    messageController.clear();
    sendTypingStatus(false);
  }

  void sendTypingStatus(bool typing) {
    socketService.socket?.emit('chat:typing', {
      'rideId': rideId,
      'senderId': currentUserId,
      'senderType': 'Driver',
      'isTyping': typing
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    socketService.socket?.off('message:receive');
    socketService.socket?.off('chat:typing');
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
