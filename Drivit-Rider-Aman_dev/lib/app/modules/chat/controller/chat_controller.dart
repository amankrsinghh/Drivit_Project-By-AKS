import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';

class ChatController extends GetxController {
  final SocketService socketService = Get.find<SocketService>();
  
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  
  final messages = <Map<String, dynamic>>[].obs;
  final isTyping = false.obs;
  
  late String rideId;
  final otherParticipantName = "".obs;
  final otherParticipantId = "".obs;
  final otherParticipantImage = "".obs;
  final otherParticipantRating = "0.0".obs;
  final otherParticipantExp = "".obs;
  late String currentUserId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    rideId = args['rideId'];
    
    // Initial data from args
    otherParticipantName.value = args['name'] ?? "Driver";
    otherParticipantId.value = args['otherId'] ?? "";
    otherParticipantImage.value = args['image'] ?? "";
    otherParticipantRating.value = args['rating'] ?? "0.0";
    otherParticipantExp.value = args['exp'] ?? "";
    
    _initChat();
    _fetchRealTimeDriverDetails();
  }

  Future<void> _fetchRealTimeDriverDetails() async {
    try {
      final res = await ApiService.getRideById(rideId);
      final ride = res['data'] ?? res;
      if (ride != null && ride['driverId'] != null) {
        final driver = ride['driverId'];
        if (driver is Map) {
          otherParticipantName.value = driver['name'] ?? otherParticipantName.value;
          otherParticipantId.value = driver['_id']?.toString() ?? otherParticipantId.value;
          otherParticipantImage.value = ApiService.getImageUrl(driver['profileImage']?.toString());
          final double total = (driver['totalRating'] ?? 0.0).toDouble();
          final int count = (driver['ratingCount'] ?? 0).toInt();
          otherParticipantRating.value = count > 0 ? (total / count).toStringAsFixed(1) : "0.0";
          otherParticipantExp.value = "${driver['expYear'] ?? '0'} years of exp";
        }
      }
    } catch (e) {
      debugPrint("Error fetching driver details in chat: $e");
    }
  }

  void _initChat() async {
    currentUserId = await ApiService.getCustomerId() ?? '';
    
    // Join ride room
    socketService.joinRide(rideId);
    
    // Listen for messages
    socketService.socket?.on('message:receive', (data) {
      messages.add(data);
      _scrollToBottom();
    });

    // Listen for typing
    socketService.socket?.on('chat:typing', (data) {
      if (data['senderId'] == otherParticipantId.value) {
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
      'senderType': 'Customer',
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
      'senderType': 'Customer',
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
