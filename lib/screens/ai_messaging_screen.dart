import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AIMessagingScreen extends StatefulWidget {
  const AIMessagingScreen({super.key});

  @override
  State<AIMessagingScreen> createState() => _AIMessagingScreenState();
}

class _AIMessagingScreenState extends State<AIMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAILoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isAI': true,
      'text': 'Assalam-o-Alaikum! I am your HomeService NLU Orchestrator. Tell me what issue you are facing in Roman Urdu, Urdu, or English (e.g. "washroom ka sink leak ho raha hai jaldi kisi ko bhejo" or "kitchen light not working abhi bhejo"). I will parse your request in real-time!',
      'hasAction': false,
    }
  ];

  // --- Core NLU Engine Heuristics ---
  Map<String, dynamic> _parseNLU(String text) {
    final String rawText = text.toLowerCase();
    
    // 1. Detect service categories
    final List<String> matchedCategories = [];
    
    if (rawText.contains('electric') || 
        rawText.contains('bijli') || 
        rawText.contains('wire') || 
        rawText.contains('fuse') || 
        rawText.contains('switch') || 
        rawText.contains('spark') || 
        rawText.contains('current') || 
        rawText.contains('board short') || 
        rawText.contains('fan') || 
        rawText.contains('light')) {
      matchedCategories.add('Electrician');
    }
    
    if (rawText.contains('plumb') || 
        rawText.contains('leak') || 
        rawText.contains('sink') || 
        rawText.contains('pipe') || 
        rawText.contains('tap') || 
        rawText.contains('drain') || 
        rawText.contains('toilet') || 
        rawText.contains('flush') || 
        rawText.contains('water') || 
        rawText.contains('pani') || 
        rawText.contains('nal') || 
        rawText.contains('chok') || 
        rawText.contains('block') || 
        rawText.contains('basin')) {
      matchedCategories.add('Plumber');
    }

    if (rawText.contains('ac ') || 
        rawText.contains('air condition') || 
        rawText.contains('cooling') || 
        rawText.contains('split') || 
        rawText.contains('compressor') || 
        rawText.contains('chilling')) {
      matchedCategories.add('AC Technician');
    }

    if (rawText.contains('carpenter') || 
        rawText.contains('furniture') || 
        rawText.contains('wood') || 
        rawText.contains('table') || 
        rawText.contains('chair') || 
        rawText.contains('door') || 
        rawText.contains('sofa') || 
        rawText.contains('bed') || 
        rawText.contains('cabinet')) {
      matchedCategories.add('Carpenter');
    }

    if (rawText.contains('fridge') || 
        rawText.contains('refrigerator') || 
        rawText.contains('oven') || 
        rawText.contains('microwave') || 
        rawText.contains('iron') || 
        rawText.contains('dryer') || 
        rawText.contains('washing machine') || 
        rawText.contains('geyser') || 
        rawText.contains('heater') || 
        rawText.contains('tv') || 
        rawText.contains('television') || 
        rawText.contains('appliance') || 
        rawText.contains('machin')) {
      matchedCategories.add('Home Appliances Repair');
    }

    if (rawText.contains('deep clean') || 
        rawText.contains('dusting') || 
        rawText.contains('pocha') || 
        rawText.contains('vacuum') || 
        rawText.contains('safai') || 
        rawText.contains('sweep')) {
      matchedCategories.add('Deep Cleaning');
    }

    if (rawText.contains('water tank') || 
        rawText.contains('tanki') || 
        rawText.contains('tank clean') || 
        rawText.contains('tank safai')) {
      matchedCategories.add('Water Tank Cleaning');
    }

    if (rawText.contains('pest') || 
        rawText.contains('spray') || 
        rawText.contains('insect') || 
        rawText.contains('cockroach') || 
        rawText.contains('dengue') || 
        rawText.contains('termite') || 
        rawText.contains('keeray') || 
        rawText.contains('khutmal') || 
        rawText.contains('bedbug')) {
      matchedCategories.add('Pest Control');
    }

    if (rawText.contains('garden') || 
        rawText.contains('grass') || 
        rawText.contains('plant') || 
        rawText.contains('flower') || 
        rawText.contains('lawn') || 
        rawText.contains('tree') || 
        rawText.contains('mali')) {
      matchedCategories.add('Gardener');
    }

    if (rawText.contains('laundry') || 
        rawText.contains('dry clean') || 
        rawText.contains('dhona') || 
        rawText.contains('dhobi') || 
        rawText.contains('suit') || 
        rawText.contains('press') || 
        rawText.contains('istri')) {
      matchedCategories.add('Laundry & Dry Cleaning');
    }

    if (rawText.contains('tutor') || 
        rawText.contains('teach') || 
        rawText.contains('study') || 
        rawText.contains('class') || 
        rawText.contains('math') || 
        rawText.contains('english') || 
        rawText.contains('science') || 
        rawText.contains('padhana') || 
        rawText.contains('parhana') || 
        rawText.contains('teacher')) {
      matchedCategories.add('Home Tutor');
    }

    if (rawText.contains('generator') || 
        rawText.contains('ups') || 
        rawText.contains('battery') || 
        rawText.contains('generator oil')) {
      matchedCategories.add('Generator Mechanic');
    }

    if (rawText.contains('paint') || 
        rawText.contains('rang') || 
        rawText.contains('color') || 
        rawText.contains('wall') || 
        rawText.contains('distemper') ||
        rawText.contains('painter')) {
      matchedCategories.add('Painter');
    }

    if (rawText.contains('solar') || 
        rawText.contains('plate') || 
        rawText.contains('solar clean') || 
        rawText.contains('panel')) {
      matchedCategories.add('Solar Panel Cleaning');
    }

    if (rawText.contains('maid') || 
        rawText.contains('maseeha') || 
        rawText.contains('kaam wali') || 
        rawText.contains('kamwali') || 
        rawText.contains('bartan') || 
        rawText.contains('cleaning maid')) {
      matchedCategories.add('Home Maid');
    }

    if (rawText.contains('beauty') || 
        rawText.contains('makeup') || 
        rawText.contains('salon') || 
        rawText.contains('facial') || 
        rawText.contains('hair') || 
        rawText.contains('parlor') || 
        rawText.contains('henna') || 
        rawText.contains('mehndi') || 
        rawText.contains('waxing')) {
      matchedCategories.add('Home beauticians');
    }

    // Severity hierarchy classification
    String detectedService = 'Others';
    if (matchedCategories.isNotEmpty) {
      if (matchedCategories.contains('Electrician')) {
        detectedService = 'Electrician';
      } else if (matchedCategories.contains('AC Technician')) {
        detectedService = 'AC Technician';
      } else if (matchedCategories.contains('Generator Mechanic')) {
        detectedService = 'Generator Mechanic';
      } else if (matchedCategories.contains('Plumber')) {
        detectedService = 'Plumber';
      } else if (matchedCategories.contains('Water Tank Cleaning')) {
        detectedService = 'Water Tank Cleaning';
      } else if (matchedCategories.contains('Solar Panel Cleaning')) {
        detectedService = 'Solar Panel Cleaning';
      } else if (matchedCategories.contains('Home Appliances Repair')) {
        detectedService = 'Home Appliances Repair';
      } else if (matchedCategories.contains('Carpenter')) {
        detectedService = 'Carpenter';
      } else if (matchedCategories.contains('Painter')) {
        detectedService = 'Painter';
      } else if (matchedCategories.contains('Pest Control')) {
        detectedService = 'Pest Control';
      } else if (matchedCategories.contains('Deep Cleaning')) {
        detectedService = 'Deep Cleaning';
      } else if (matchedCategories.contains('Laundry & Dry Cleaning')) {
        detectedService = 'Laundry & Dry Cleaning';
      } else if (matchedCategories.contains('Home Tutor')) {
        detectedService = 'Home Tutor';
      } else if (matchedCategories.contains('Home Maid')) {
        detectedService = 'Home Maid';
      } else if (matchedCategories.contains('Home beauticians')) {
        detectedService = 'Home beauticians';
      } else if (matchedCategories.contains('Gardener')) {
        detectedService = 'Gardener';
      } else {
        detectedService = 'Others';
      }
    }

    // 2. Urgency Detection
    bool isHighUrgency = false;
    if (rawText.contains('jaldi') || 
        rawText.contains('abhi') || 
        rawText.contains('urgent') || 
        rawText.contains('immediately') || 
        rawText.contains('right now') || 
        rawText.contains('emergency') || 
        rawText.contains('fauri') || 
        rawText.contains('asap') ||
        rawText.contains('aag') ||
        rawText.contains('fire') ||
        rawText.contains('spark') ||
        rawText.contains('short') ||
        rawText.contains('flood') ||
        rawText.contains('escaping') ||
        rawText.contains('bahar aa')) {
      isHighUrgency = true;
    }
    String urgency = isHighUrgency ? 'High' : 'Standard';

    // 3. Location / Context detection
    final List<String> locationTokens = [
      'washroom', 'kitchen', 'bedroom', 'balcony', 'gate', 'flat 2', 'roof',
      'room', 'ghar', 'bathroom', 'flat', 'main gate', 'board', 'sink', 'switch'
    ];
    String? detectedLocation;
    for (final loc in locationTokens) {
      if (rawText.contains(loc)) {
        detectedLocation = loc;
        break;
      }
    }

    // Auto-trigger evaluates to true if the intent matches unambiguously and location context exists
    bool autoTrigger = (matchedCategories.isNotEmpty && detectedLocation != null);

    // 4. Extracted Keywords captures problem cues without common stopwords
    final List<String> stopwords = [
      'ka', 'ki', 'ke', 'hai', 'aur', 'ko', 'se', 'un', 'wo', 'he', 'she', 
      'it', 'is', 'a', 'an', 'the', 'for', 'with', 'ho', 'raha', 'gaya', 
      'sakte', 'saktay', 'liye', 'yaar', 'jo', 'hoga', 'koee', 'mil'
    ];

    final List<String> extractedKeywords = [];

    // Capture standard idioms
    if (rawText.contains('sink leak')) extractedKeywords.add('sink leak');
    if (rawText.contains('board short')) extractedKeywords.add('board short');
    if (rawText.contains('switch jal')) extractedKeywords.add('switch jal gaya');
    if (rawText.contains('pani bahar')) extractedKeywords.add('pani bahar');
    if (rawText.contains('kal subah')) extractedKeywords.add('kal subah');

    // Add individual filtered words
    final List<String> tokens = rawText
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'));

    for (final token in tokens) {
      if (token.length > 2 && 
          !stopwords.contains(token) && 
          extractedKeywords.length < 8) {
        bool duplicate = false;
        for (final exist in extractedKeywords) {
          if (exist.contains(token) || token.contains(exist)) {
            duplicate = true;
            break;
          }
        }
        if (!duplicate) {
          extractedKeywords.add(token);
        }
      }
    }

    if (extractedKeywords.isEmpty) {
      extractedKeywords.add('request');
    }

    return {
      'detected_service': detectedService,
      'urgency': urgency,
      'auto_trigger_notification': autoTrigger,
      'extracted_keywords': extractedKeywords.take(8).toList(),
    };
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'isAI': false,
        'text': text,
        'hasAction': false,
      });
      _isAILoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    // Trigger local NLU parsing & simulate AI orchestration
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      final nlu = _parseNLU(text);
      final String service = nlu['detected_service'];
      
      String aiText = '';
      String providerName = '';
      String providerRate = '';
      String phone = '';
      String providerUid = '';
      bool foundProvider = false;
      
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .get()
            .timeout(const Duration(seconds: 5));
            
        final allProviders = querySnapshot.docs;
        
        // Find best matched provider using NLU similarity scoring!
        Map<String, dynamic>? bestProvider;
        double bestScore = 0.0;
        
        for (final doc in allProviders) {
          final data = doc.data() as Map<String, dynamic>;
          final String provName = (data['fullName'] ?? '').toString().toLowerCase();
          final String provCategory = (data['serviceCategory'] ?? '').toString().toLowerCase();
          final String provSkills = (data['skills'] ?? '').toString().toLowerCase();
          final String provBio = (data['bio'] ?? '').toString().toLowerCase();
          
          double score = 0.0;
          
          // Match 1: Exact category match (highest weight)
          if (provCategory == service.toLowerCase()) {
            score += 10.0;
          } else if (provCategory.contains(service.toLowerCase()) || service.toLowerCase().contains(provCategory)) {
            score += 5.0;
          }
          
          // Match 2: Extracted keywords presence in skills, bio or name
          final List kws = nlu['extracted_keywords'] ?? [];
          for (final kw in kws) {
            final String kwLower = kw.toString().toLowerCase();
            if (provCategory.contains(kwLower)) score += 3.0;
            if (provSkills.contains(kwLower)) score += 2.0;
            if (provBio.contains(kwLower)) score += 1.0;
            if (provName.contains(kwLower)) score += 1.5;
          }
          
          if (score > bestScore && score > 0) {
            bestScore = score;
            bestProvider = data;
          }
        }
        
        if (bestProvider != null) {
          providerName = bestProvider['fullName'] ?? 'Provider';
          final rate = bestProvider['hourlyRate'] ?? '1,000';
          providerRate = 'PKR $rate/hour';
          phone = bestProvider['phoneNumber'] ?? '03001234567';
          providerUid = bestProvider['uid'] ?? '';
          foundProvider = true;
          
          aiText = 'I have identified a $service request and matched you with our top-rated local expert: $providerName ($providerRate) whose profile strongly matches your requirements. Would you like me to connect you right now?';
        }
      } catch (e) {
        print('Warning: AI Firestore provider query failed: $e');
      }

      if (!foundProvider) {
        aiText = 'I have detected a $service request. Currently, we do not have any registered providers under the "$service" category in the database, but I can match you as soon as one joins! Would you like to check other services?';
        providerName = 'No Real Provider Registered';
        providerRate = 'N/A';
      }

      setState(() {
        _messages.add({
          'isAI': true,
          'text': aiText,
          'hasAction': foundProvider,
          'actionType': 'suggest_provider',
          'nluData': nlu,
          'providerName': providerName,
          'providerRate': providerRate,
          'providerPhone': phone,
          'providerUid': providerUid,
          'detectedService': service,
        });
        _isAILoading = false;
      });
      _scrollToBottom();
    });
  }

  void _handleAction(bool accepted, String provider, String rate, {String? phone, String? providerUid, String? service}) {
    setState(() {
      _messages.add({
        'isAI': false,
        'text': accepted ? 'Yes, connect me immediately.' : 'No, search other local options.',
        'hasAction': false,
      });
      _isAILoading = true;
    });
    _scrollToBottom();

    if (accepted && providerUid != null && providerUid.isNotEmpty) {
      _sendNotificationToProvider(
        providerUid, 
        service ?? 'Home service',
        providerName: provider,
        providerRate: rate,
      );
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isAILoading = false;
        if (accepted) {
          _messages.add({
            'isAI': true,
            'text': 'Perfect! I have auto-triggered a priority dispatch notification to $provider. You can now chat directly and securely to manage your booking!',
            'hasAction': true,
            'actionType': 'connected',
            'providerName': provider,
            'providerRate': rate,
            'providerPhone': phone,
          });
        } else {
          _messages.add({
            'isAI': true,
            'text': 'No problem. I will keep scanning other top-rated profiles in your area showing PKR rates.',
            'hasAction': false,
          });
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _sendNotificationToProvider(
    String providerUid, 
    String service, {
    required String providerName, 
    required String providerRate,
  }) async {
    try {
      final seeker = FirebaseAuth.instance.currentUser;
      if (seeker == null) return;

      // Check for existing emergency alert to prevent duplicate requests
      final existingCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerUid)
          .collection('notifications')
          .where('seekerId', isEqualTo: seeker.uid)
          .where('service', isEqualTo: service)
          .where('type', isEqualTo: 'emergency_alert')
          .limit(1)
          .get();

      if (existingCheck.docs.isNotEmpty) {
        print('Duplicate request detected, skipping notification.');
        return;
      }

      String seekerName = seeker.displayName ?? 'A Seeker';
      String seekerPhone = seeker.phoneNumber ?? 'N/A';

      final seekerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(seeker.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (seekerDoc.exists) {
        seekerName = seekerDoc.data()?['fullName'] ?? seekerName;
        seekerPhone = seekerDoc.data()?['phoneNumber'] ?? seekerPhone;
      }

      // Pre-generate a unified booking document reference ID
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

      // 1. Write live alert to provider notifications subcollection (linked to bookingRef.id)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(providerUid)
          .collection('notifications')
          .add({
            'title': '🚨 EMERGENCY booking request from $seekerName!',
            'body': 'Emergency $service request has been auto-triggered!',
            'createdAt': FieldValue.serverTimestamp(),
            'seekerId': seeker.uid,
            'seekerPhone': seekerPhone,
            'seekerName': seekerName,
            'service': service,
            'bookingId': bookingRef.id,
            'providerName': providerName,
            'providerRate': providerRate,
            'type': 'emergency_alert',
            'isRead': false,
          })
          .timeout(const Duration(seconds: 5));

      // 2. Write global booking transaction document as 'Pending'
      await bookingRef.set({
        'seekerId': seeker.uid,
        'seekerName': seekerName,
        'seekerPhone': seekerPhone,
        'providerId': providerUid,
        'providerName': providerName,
        'providerRate': providerRate,
        'service': service,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      })
      .timeout(const Duration(seconds: 5));

      print('Emergency Dispatch alert and Booking successfully posted to Firestore!');
    } catch (e) {
      print('Warning: Failed to write emergency dispatch notification/booking: $e');
    }
  }

  Future<void> _sendSMS(String phoneNumber, String messageBody) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': messageBody,
      },
    );
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(messageBody)}'));
      }
    } catch (e) {
      print('Error launching SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open SMS. Provider Phone: $cleanPhone'),
            backgroundColor: const Color(0xFF6B46C1),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Area
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isAILoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Enter your request (Roman Urdu, Urdu, or English)...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFA0AEC0)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF6B46C1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B46C1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isAI = msg['isAI'];
    final bool hasAction = msg['hasAction'] ?? false;
    final String actionType = msg['actionType'] ?? '';
    final Map<String, dynamic>? nlu = msg['nluData'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAI ? const Color(0xFFF7FAFC) : const Color(0xFF6B46C1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAI ? 0 : 16),
                  bottomRight: Radius.circular(isAI ? 16 : 0),
                ),
                border: isAI ? Border.all(color: const Color(0xFFE2E8F0)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Natural Response Text
                  Text(
                    msg['text'],
                    style: GoogleFonts.inter(
                      color: isAI ? const Color(0xFF1A202C) : Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  // NLU Orchestrator Visualization Card
                  if (nlu != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A202C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '🧠 NLU ORCHESTRATOR',
                                style: GoogleFonts.firaCode(
                                  color: const Color(0xFF9F7AEA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: nlu['urgency'] == 'High' 
                                      ? const Color(0xFFE53E3E) 
                                      : const Color(0xFF3182CE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  nlu['urgency'] == 'High' ? '🚨 HIGH URGENCY' : 'STANDARD',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF4A5568), height: 16),
                          
                          // Auto trigger info
                          Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: Color(0xFFA0AEC0)),
                              const SizedBox(width: 8),
                              Text(
                                'Auto Trigger:',
                                style: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                nlu['auto_trigger_notification'] ? 'TRUE (Context OK)' : 'FALSE',
                                style: GoogleFonts.firaCode(
                                  color: nlu['auto_trigger_notification'] ? const Color(0xFF38A169) : const Color(0xFFE53E3E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Extracted Keywords
                          Text(
                            'Keywords:',
                            style: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (nlu['extracted_keywords'] as List).map((kw) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D3748),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF4A5568)),
                                ),
                                child: Text(
                                  kw.toString(),
                                  style: GoogleFonts.firaCode(color: Colors.white, fontSize: 10),
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(color: Color(0xFF4A5568), height: 20),
                          
                          // Schema JSON Output
                          Text(
                            'Strict JSON Schema Output:',
                            style: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3748),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SelectableText(
                              const JsonEncoder.withIndent('  ').convert(nlu),
                              style: GoogleFonts.firaCode(
                                color: const Color(0xFF68D391),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (hasAction && actionType == 'suggest_provider') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _handleAction(
                            true, 
                            msg['providerName'] ?? 'Specialist', 
                            msg['providerRate'] ?? 'PKR 1,000',
                            phone: msg['providerPhone'],
                            providerUid: msg['providerUid'],
                            service: msg['detectedService'],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38A169),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          child: Text('Connect Me', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _handleAction(
                            false, 
                            msg['providerName'] ?? 'Specialist', 
                            msg['providerRate'] ?? 'PKR 1,000'
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A5568),
                            side: const BorderSide(color: Color(0xFFCBD5E0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                  if (hasAction && actionType == 'connected') ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final String pPhone = msg['providerPhone'] ?? '03001234567';
                        final String pName = msg['providerName'] ?? 'Provider';
                        final String msgBody = 'Hello $pName, I saw your home service profile on the Home Service app and would like to hire you! Please let me know when you are available.';
                        _sendSMS(pPhone, msgBody);
                      },
                      icon: const Icon(Icons.message, size: 16, color: Colors.white),
                      label: Text('Message Provider Now', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3182CE),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF4A5568), size: 16),
            ),
          ],
        ],
      ),
    );
  }
}