import 'package:flutter/material.dart';
import '../../../shared/utils/auth_helper.dart';
import '../../../shared/widgets/meditrack_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _prefillDemo() {
    setState(() {
      if (_isSignUpMode) {
        _nameController.text = 'Thomas Wright';
        _emailController.text = 'thomas@meditrack.com';
        _passwordController.text = 'password123';
        _ageController.text = '76';
        _bloodGroupController.text = 'B+';
      } else {
        _emailController.text = 'margaret@meditrack.com';
        _nameController.text = 'Margaret Chen';
        _passwordController.text = 'password123';
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    final email = _emailController.text.trim();
    final name = _nameController.text.trim().isEmpty ? 'Elder User' : _nameController.text.trim();

    bool success = false;
    if (_isSignUpMode) {
      final age = int.tryParse(_ageController.text.trim()) ?? 75;
      final bloodGroup = _bloodGroupController.text.trim().isEmpty ? 'O+' : _bloodGroupController.text.trim();
      success = await AuthHelper().login(
        email,
        name,
        age: age,
        bloodGroup: bloodGroup,
        syncStatus: 0, 
      );
    } else {
      success = await AuthHelper().login(email, name);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check credentials.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF818CF8).withValues(alpha: 0.35),
                    const Color(0xFF6366F1).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF43F5E).withValues(alpha: 0.25),
                    const Color(0xFFF43F5E).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo Area
                      const Center(
                        child: MediTrackLogo(size: 96),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'MediTrack',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Elder Care Sync Platform',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Card Wrapper
                      Card(
                        elevation: 12,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _isSignUpMode ? 'Elder Registration' : 'Patient/Elder Log',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Signup fields (only in Elderly Mode when isSignUpMode is true)
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 350),
                                  crossFadeState: _isSignUpMode
                                      ? CrossFadeState.showFirst
                                      : CrossFadeState.showSecond,
                                  firstChild: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: TextFormField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            labelText: 'Full Name',
                                            hintText: 'Enter your name',
                                            prefixIcon: Icon(Icons.person_outline_rounded),
                                          ),
                                          validator: (value) {
                                            if (_isSignUpMode && (value == null || value.trim().isEmpty)) {
                                              return 'Please enter your name';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
                                              child: TextFormField(
                                                controller: _ageController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText: 'Age',
                                                  hintText: 'e.g. 78',
                                                  prefixIcon: Icon(Icons.calendar_today_rounded),
                                                ),
                                                validator: (value) {
                                                  if (_isSignUpMode) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return 'Enter age';
                                                    }
                                                    if (int.tryParse(value) == null) {
                                                      return 'Invalid';
                                                    }
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
                                              child: TextFormField(
                                                controller: _bloodGroupController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Blood Group',
                                                  hintText: 'e.g. O+',
                                                  prefixIcon: Icon(Icons.bloodtype_outlined),
                                                ),
                                                validator: (value) {
                                                  if (_isSignUpMode && (value == null || value.trim().isEmpty)) {
                                                    return 'Enter group';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  secondChild: const SizedBox.shrink(),
                                ),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'Enter email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter security pin/password',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.trim().length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Login/Signup Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSignUpMode ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isSignUpMode ? 'CREATE ACCOUNT' : 'SIGN IN & ACCESS',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                ),

                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSignUpMode = !_isSignUpMode;
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _nameController.clear();
                                      _ageController.clear();
                                      _bloodGroupController.clear();
                                    });
                                  },
                                  child: Text(
                                    _isSignUpMode
                                        ? 'Already have an account? Sign In'
                                        : "Don't have an account? Register Now",
                                    style: TextStyle(
                                      color: _isSignUpMode ? const Color(0xFF1D9E75) : const Color(0xFF6366F1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Demo credentials quick access
                      TextButton.icon(
                        onPressed: _prefillDemo,
                        icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFF59E0B)),
                        label: const Text(
                          'Prefill Elder Demo',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
