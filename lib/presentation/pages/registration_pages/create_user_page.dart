import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/app_preferences_service.dart';

class CreateUserPage extends StatefulWidget {
  final String phoneNumber;

  const CreateUserPage({required this.phoneNumber, super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    // _emailController.dispose();
    _fullnameController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _districtController.dispose();

    super.dispose();
  }

  void _createAccount() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, ismingizni kiriting')),
      );

      // if (_fullnameController.text.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Iltimos, familyangizni  kiriting')),
      //   );
      // }

      // if (_regionController.text.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Iltimos, Viloyatni tanlang')),
      //   );
      // }

      // if (_cityController.text.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Iltimos, Shaharni tanlang')),
      //   );
      // }

      // if (_districtController.text.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Iltimos, Tumaningzni  tanlang')),
      //   );

      return;
    }

    setState(() => _isLoading = true);

    // Simulate account creation
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        setState(() => _isLoading = false);

        // Save user name and mark onboarding as completed
        final prefs = AppPreferencesService();
        await prefs.setUserName(_nameController.text);
        await prefs.setOnboardingCompleted();

        if (mounted) {
          context.go('/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Yaratish'), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Center(
                child: Text(
                  'Profilingizni To\'ldiring',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),

              // const SizedBox(height: 12),
              // Text(
              //   'Shaxsiy ma\'lumotlaringizni to\'ldirish orqali ro\'yxatdan o\'tin',
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              // //const SizedBox(height: 40),
              // // Avatar
              // // Center(
              // // child: Column(
              // //   children: [
              // //     // Container(
              // //     //   width: 100,
              // //     //   height: 100,
              // //     //   decoration: BoxDecoration(
              // //     //     shape: BoxShape.circle,
              // //     //     gradient: LinearGradient(
              // //     //       begin: Alignment.topLeft,
              // //     //       end: Alignment.bottomRight,
              // //     //       colors: [
              // //     //         AppColors.primaryGreen.withOpacity(0.3),
              // //     //         AppColors.primaryGreenLight.withOpacity(0.3),
              // //     //       ],
              // //     //     ),
              // //     //   ),
              // //     //   child: const Icon(
              // //     //     Icons.person,
              // //     //     size: 50,
              // //     //     color: AppColors.primaryGreen,
              // //     //   ),
              // //     // ),
              // //     //const SizedBox(height: 16),
              // //     // GestureDetector(
              // //     //   onTap: () {
              // //     //     ScaffoldMessenger.of(context).showSnackBar(
              // //     //       const SnackBar(
              // //     //         content: Text(
              // //     //           'Rasm yuklash tez orada mavjud bo\'ladi',
              // //     //         ),
              // //     //       ),
              // //     //     );
              // //     //   },
              // //     //   child: Text(
              // //     //     'Rasim Yukla',
              // //     //     style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              // //     //       color: AppColors.primaryGreen,
              // //     //       fontWeight: FontWeight.w600,
              // //     //     ),
              // //     //   ),
              // //     // ),
              // //   ],
              // // ),
              // // ),
              const SizedBox(height: 40),

              Text('Ism', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ismingizni kiriting',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text('Familya', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _fullnameController,
                decoration: InputDecoration(
                  hintText: 'Famiyangizni kiriting',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text('Viloyat', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _regionController,
                decoration: InputDecoration(
                  hintText: 'Viloyatni tanlang',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text('Shahar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'Shaharni tanlang',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text('Tuman', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _districtController,
                decoration: InputDecoration(
                  hintText: 'Tumanni tanlang',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Name Field

              // const SizedBox(height: 24),
              // Email Field
              // Text(
              //   'Email (Ixtiyoriy)',
              //   style: Theme.of(context).textTheme.titleLarge,
              // // ),
              // const SizedBox(height: 8),
              // TextField(
              //   controller: _emailController,
              //   decoration: InputDecoration(
              //     hintText: 'Email kiriting',
              //     prefixIcon: const Icon(Icons.email_outlined),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //   ),
              //   keyboardType: TextInputType.emailAddress,
              // ),
              // const SizedBox(height: 24),
              // // Currency Selection
              // Text(
              //   'Asosiy Valyuta',
              //   style: Theme.of(context).textTheme.titleLarge,
              // ),
              // const SizedBox(height: 8),
              // Container(
              //   decoration: BoxDecoration(
              //     border: Border.all(color: AppColors.borderGrey),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 16),
              //     child: DropdownButton<String>(
              //       isExpanded: true,
              //       value: _selectedCurrency,
              //       underline: const SizedBox(),
              //       items: ['UZS', 'USD', 'RUB', 'EUR']
              //           .map(
              //             (String value) => DropdownMenuItem<String>(
              //               value: value,
              //               child: Text(value),
              //             ),
              //           )
              //           .toList(),
              //       onChanged: (String? newValue) {
              //         if (newValue != null) {
              //           setState(() => _selectedCurrency = newValue);
              //         }
              //       },
              //     ),
              //   ),
              // ),
              const SizedBox(height: 40),
              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '  Davom Etish',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
