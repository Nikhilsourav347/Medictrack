import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/utils/auth_helper.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  bool _accepted = false;
  bool _isLoggedIn = false;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How often should I record vitals?',
      'answer': 'It is generally recommended to record vitals once or twice daily, or as advised by your doctor. Consistency is key to tracking trends.',
    },
    {
      'question': 'Can I use the app without internet?',
      'answer': 'Yes, MediTrack supports offline mode. Your data is stored locally on your device and will sync automatically when you are back online.',
    },
    {
      'question': 'Will my data be uploaded?',
      'answer': 'Yes, your logs are securely backed up and synced to the cloud database when internet is available, allowing you to access them anytime.',
    },
    {
      'question': 'Can I share reports with doctors?',
      'answer': 'Yes, you can generate and export beautiful PDF health summaries of your vitals and medicines to share during doctor visits.',
    },
    {
      'question': 'Can developers see my data?',
      'answer': 'No, all your health data is private, local-first, and encrypted during transmission. We respect your privacy.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    final loggedIn = AuthHelper().isLoggedIn;
    setState(() {
      _isLoggedIn = loggedIn;
      if (loggedIn) {
        _accepted = true; // Auto check if already logged in and looking from dashboard
      }
    });
  }

  Future<void> _handleProceed() async {
    if (!_accepted) return;
    await AuthHelper().acceptPrecautions();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _isLoggedIn 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'How to Use MediTrack',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // FAQ Accordion
                    ..._faqs.map((faq) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ExpansionTile(
                          iconColor: const Color(0xFF1D9E75),
                          collapsedIconColor: Colors.grey.shade400,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            faq['question']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              child: Text(
                                faq['answer']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    
                    const SizedBox(height: 16),
                    
                    // Medical Disclaimer/Precaution Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2), // Very light rose/red
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFECDD3), // Light red border
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.gpp_maybe_rounded,
                            color: Color(0xFFE11D48), // Deep rose warning
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Precaution & Disclaimer',
                                  style: TextStyle(
                                    color: Color(0xFF9F1239), // Dark rose text
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'MediTrack is intended for personal health tracking and educational purposes only. It does not diagnose diseases or replace professional medical advice. Always consult qualified healthcare professionals regarding medications and treatment.',
                                  style: TextStyle(
                                    color: Color(0xFFE11D48), // Rose description
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Drawer (only required if not logged in)
            if (!_isLoggedIn)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _accepted,
                            onChanged: (val) {
                              setState(() => _accepted = val ?? false);
                            },
                            activeColor: const Color(0xFF1D9E75),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'I understand and agree to the precautions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _accepted ? _handleProceed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          disabledBackgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _accepted ? 3 : 0,
                          shadowColor: const Color(0xFF1D9E75).withValues(alpha: 0.3),
                        ),
                        child: Text(
                          'PROCEED TO LOGIN',
                          style: TextStyle(
                            color: _accepted ? Colors.white : Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
