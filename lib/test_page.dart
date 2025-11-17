import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:kassam/presentation/pages/home_page/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackMoney UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Montserrat', // Masalan, shunga o'xshash font tanlash
      ),
      home: const HomePage(), // Kirish ekranidan boshlaymiz
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Gradientni hosil qilish uchun funksiya
  BoxDecoration _buildBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 134, 129, 129),
          Color.fromARGB(255, 134, 223, 134),
        ], // Qora va to'q yashil
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar orqasida fonni davom ettirish
      body: Container(
        decoration: _buildBackground(),
        child: Stack(
          children: [
            // Asosiy kontent
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 250.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo va ikonka
                    const Icon(
                      Icons
                          .monetization_on, // Yoki Stack yordamida ikkita ikonkani birlashtirish
                      size: 80,
                      color: Colors.lightGreenAccent,
                    ),
                    const SizedBox(height: 10),


                    // Brend nomi
                    const Text(
                      'HISOBCHIM', 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
 
                    const SizedBox(height: 5),

                    // Slogan
                    const Text(
                      'Hisobni boshqarish biz bilan osonroq',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const Spacer(),

                    // "Get Started" tugmasi
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 118, 203, 118),
                              Color(0xFF00CC00),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(25),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Boshlash',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  // Ikkala ekranning fonini bir xil qilish
  BoxDecoration _buildBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 134, 129, 129),
          Color.fromARGB(255, 134, 223, 134),

          Color.fromARGB(255, 118, 203, 118),
          Color.fromARGB(255, 88, 231, 88),
        ],
        begin: Alignment.topRight,

        end: Alignment.bottomLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController phoneController = TextEditingController();
    String fullPhoneNumber = '';
    Color brightGreenAccent = Colors.lightGreenAccent;
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: _buildBackground(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo qismi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 30,
                      color: Colors.lightGreenAccent,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'HISOBCHIM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Ro'yxatdan o'tish kartasi
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), // Shaffofroq rang
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Ro\'yxatdan O\'tish',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          IntlPhoneField(
                            flagsButtonPadding: EdgeInsetsGeometry.all(10),
                            showDropdownIcon: false,
                            validator: (value) {
                              if (value == null ||
                                  value.number.isEmpty ||
                                  value.number.length < 9) {
                                return 'Iltimos, to\'g\'ri telefon raqamini kiriting';
                              }
                              return null;
                            },
                            showCountryFlag: false,
                            cursorColor: brightGreenAccent,

                            initialCountryCode: "UZ",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                            decoration: InputDecoration(
                              hintMaxLines: 1,
                              prefixStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),

                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 20.0,
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),

                              // Fokuslanganda yashil rangdagi bordyur
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: brightGreenAccent,
                                  width: 1,
                                ),
                              ),
                            ),

                            onChanged: (phone) {
                              fullPhoneNumber = "998${phone.number}";
                            },
                          ),

                          const SizedBox(height: 25),

                          // Sign Up tugmasi
                          _buildGreenButton(
                            text: 'SMS Code\'ni olish',

                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Yashil tugma komponenti
  Widget _buildGreenButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF008000), Color(0xFF00CC00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.transparent, // Backgroundni gradientga beramiz
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Google tugmasi komponenti
  Widget _buildGoogleButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF1E1E1E), // To'q qora rang
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
