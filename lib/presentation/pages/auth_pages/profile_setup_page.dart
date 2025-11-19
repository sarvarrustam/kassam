// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';

// import 'package:kassam/presentation/theme/app_theme.dart';

// class ProfileSetupPage extends StatefulWidget {
//   final String phoneNumber;

//   const ProfileSetupPage({Key? key, required this.phoneNumber})
//     : super(key: key);

//   @override
//   State<ProfileSetupPage> createState() => _ProfileSetupPageState();
// }

// class _ProfileSetupPageState extends State<ProfileSetupPage> {
//   late TextEditingController _nameController;
//   late TextEditingController _surnameController;
//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _surnameController = TextEditingController();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _surnameController.dispose();
//     super.dispose();
//   }

//   void _registerUser() {
//     if (_formKey.currentState!.validate()) {
//       String fullName = "${_nameController.text} ${_surnameController.text}"
//           .trim();
//       context.read<AuthCubit>().registerUser(fullName);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundLight,
//       body: BlocListener<AuthCubit, AuthState>(
//         listener: (context, state) {
//           if (state is AuthSuccess) {
//             // Asosiy sahifaga o'tish
//             context.go('/home');
//           } else if (state is AuthError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: AppColors.errorRed,
//               ),
//             );
//           }
//         },
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 24),
//                 // Orqaga tugmasi
//                 IconButton(
//                   onPressed: () => context.pop(),
//                   icon: const Icon(Icons.arrow_back),
//                   color: AppColors.onBackground,
//                 ),
//                 const SizedBox(height: 24),
//                 // Sarlavha
//                 Text(
//                   "Shaxsiy Ma'lumotlar",
//                   style: Theme.of(context).textTheme.displayLarge?.copyWith(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "KASSAM'da to'liq foydalanish uchun profilingizni to'ldiring",
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                     fontSize: 14,
//                     color: const Color(0xFF666666),
//                   ),
//                 ),
//                 const SizedBox(height: 48),
//                 // Form
//                 Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       // Ism
//                       TextFormField(
//                         controller: _nameController,
//                         keyboardType: TextInputType.name,
//                         decoration: InputDecoration(
//                           labelText: "Ism",
//                           hintText: "Masalan: Ali",
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: Color(0xFFE0E0E0),
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: Color(0xFFE0E0E0),
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: AppColors.primaryGreen,
//                               width: 2,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 16,
//                           ),
//                           labelStyle: const TextStyle(color: Color(0xFF666666)),
//                         ),
//                         style: const TextStyle(
//                           color: AppColors.onBackground,
//                           fontSize: 16,
//                         ),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return "Ism bo'sh bo'lishi mumkin emas";
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       // Familiya (ixtiyoriy)
//                       TextFormField(
//                         controller: _surnameController,
//                         keyboardType: TextInputType.name,
//                         decoration: InputDecoration(
//                           labelText: "Familiya (ixtiyoriy)",
//                           hintText: "Masalan: Toshmatov",
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: Color(0xFFE0E0E0),
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: Color(0xFFE0E0E0),
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: AppColors.primaryGreen,
//                               width: 2,
//                             ),
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 16,
//                           ),
//                           labelStyle: const TextStyle(color: Color(0xFF666666)),
//                         ),
//                         style: const TextStyle(
//                           color: AppColors.onBackground,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Spacer(),
//                 // Tugma
//                 BlocBuilder<AuthCubit, AuthState>(
//                   builder: (context, state) {
//                     final isLoading = state is AuthLoading;

//                     return SizedBox(
//                       width: double.infinity,
//                       height: 56,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : _registerUser,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primaryBrown,
//                           foregroundColor: AppColors.onPrimary,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           disabledBackgroundColor: const Color(0xFFCCCCCC),
//                         ),
//                         child: isLoading
//                             ? const SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: CircularProgressIndicator(
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     AppColors.onPrimary,
//                                   ),
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 "Boshlash",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                       ),
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
