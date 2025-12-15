import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/services/api_service.dart';
import '../bloc/auth_bloc.dart';

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
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  
  // Location data
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _districts = [];
  
  String? _selectedCountryId;
  String? _selectedRegionId;
  String? _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullnameController.dispose();
    _birthdateController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Tug\'ilgan kunni tanlang',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format: 15.05.2000
        _birthdateController.text = 
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      });
    }
  }

  // API calls
  Future<void> _loadCountries() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get(apiService.getState);
      
      print('🌍 Countries response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _countries = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
        print('✅ Loaded ${_countries.length} countries');
      }
    } catch (e) {
      print('❌ Error loading countries: $e');
    }
  }

  // Viloyatlarni yuklash
  Future<void> _loadRegions(String stateId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.get(
        apiService.getRegion,
        queryParams: {'stateId': stateId},
      );
      
      print('🏙️ Regions response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _regions = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _districts = [];
          _regionController.clear();
          _districtController.clear();
        });
        print('✅ Loaded ${_regions.length} regions');
      }
    } catch (e) {
      print('❌ Error loading regions: $e');
    }
  }

  // Davlat tanlash
  void _showCountryPicker() {
    if (_countries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Davlatlar yuklanmoqda...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _countries.length,
          itemBuilder: (context, index) {
            final country = _countries[index];
            return ListTile(
              title: Text(country['name'] ?? country['title'] ?? 'Noma\'lum'),
              onTap: () {
                setState(() {
                  _cityController.text = country['name'] ?? country['title'] ?? '';
                  _selectedCountryId = country['id']?.toString();
                });
                Navigator.pop(context);
                
                // Viloyatlarni yuklash
                if (_selectedCountryId != null) {
                  _loadRegions(_selectedCountryId!);
                }
              },
            );
          },
        );
      },
    );
  }

  // Tumanlarni yuklash
  Future<void> _loadDistricts(String regionId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.get(
        apiService.getDistricts,
        queryParams: {'regionId': regionId},
      );
      
      print('🏘️ Districts response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _districts = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _districtController.clear();
        });
        print('✅ Loaded ${_districts.length} districts');
      }
    } catch (e) {
      print('❌ Error loading districts: $e');
    }
  }

  // Viloyat tanlash
  void _showRegionPicker() {
    if (_selectedCountryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval davlatni tanlang')),
      );
      return;
    }

    if (_regions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viloyatlar yuklanmoqda...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _regions.length,
          itemBuilder: (context, index) {
            final region = _regions[index];
            return ListTile(
              title: Text(region['name'] ?? region['title'] ?? 'Noma\'lum'),
              onTap: () {
                setState(() {
                  _regionController.text = region['name'] ?? region['title'] ?? '';
                  _selectedRegionId = region['id']?.toString();
                });
                Navigator.pop(context);
                
                // Tumanlarni yuklash
                if (_selectedRegionId != null) {
                  _loadDistricts(_selectedRegionId!);
                }
              },
            );
          },
        );
      },
    );
  }

  // Tuman tanlash
  void _showDistrictPicker() {
    if (_selectedRegionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avval viloyatni tanlang')),
      );
      return;
    }

    if (_districts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tumanlar yuklanmoqda...')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _districts.length,
          itemBuilder: (context, index) {
            final district = _districts[index];
            return ListTile(
              title: Text(district['name'] ?? district['title'] ?? 'Noma\'lum'),
              onTap: () {
                setState(() {
                  _districtController.text = district['name'] ?? district['title'] ?? '';
                  _selectedDistrictId = district['id']?.toString();
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }


  
  void _createAccount() {
    // Validatsiya
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, ismingizni kiriting')),
      );
      return;
    }

    if (_fullnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, familiyangizni kiriting')),
      );
      return;
    }

    if (_birthdateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, tug\'ilgan kuningizni tanlang')),
      );
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, manzilni kiriting')),
      );
      return;
    }

    // Birthday formatini API uchun o'zgartirish: 1999-09-25
    final birthday = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '';

    // BLoC event yuborish
    context.read<AuthBloc>().add(AuthCreateProfile(
          name: _nameController.text,
          surname: _fullnameController.text,
          birthday: birthday,
          address: _addressController.text,
          stateId: _selectedCountryId,
          regionId: _selectedRegionId,
          districtsId: _selectedDistrictId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileCreated) {
          // Profil muvaffaqiyatli yaratildi
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil muvaffaqiyatli yaratildi!'),
              backgroundColor: Colors.green,
            ),
          );
          // PIN kod setup sahifasiga o'tish
          context.go('/pin-setup');
        } else if (state is AuthError) {
          // Xatolik
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profil Yaratish'), elevation: 0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
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

              Text('Tug\'ilgan kun', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _birthdateController,
                readOnly: true,
                onTap: _selectBirthdate,
                decoration: InputDecoration(
                  hintText: 'Tug\'ilgan kuningizni tanlang',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),

             

              Text('Davlat', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _cityController,
                readOnly: true,
                onTap: _showCountryPicker,
                decoration: InputDecoration(
                  hintText: 'Davlatni tanlang',
                  prefixIcon: const Icon(Icons.public),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
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
                readOnly: true,
                onTap: _showRegionPicker,
                decoration: InputDecoration(
                  hintText: 'Viloyatni tanlang',
                  prefixIcon: const Icon(Icons.location_city),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
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
                readOnly: true,
                onTap: _showDistrictPicker,
                decoration: InputDecoration(
                  hintText: 'Tumanni tanlang',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),


               Text('Manzil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Manzilni kiriting',
                  prefixIcon: const Icon(Icons.home),
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
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createAccount,
                      child: isLoading
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
                              'Davom Etish',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
