import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kassam/presentation/blocs/user/user_bloc.dart';

import '../../theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is! UserLoaded) {
            return const Center(child: Text('Ma\'lumot topilmadi'));
          }

          final user = state.user;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primaryGreen,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '${user.name ?? ''} ${user.surName ?? ''}'.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryGreen,
                          AppColors.primaryGreenLight,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),

              // Profile Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Personal Info Section
                    _buildSectionTitle(context, 'Shaxsiy ma\'lumotlar'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.person, 'Ism', user.name ?? '-'),
                      _buildInfoRow(Icons.person_outline, 'Familiya', user.surName ?? '-'),
                      _buildInfoRow(Icons.cake, 'Tug\'ilgan kun', user.birthday ?? '-'),
                    ]),
                    
                    const SizedBox(height: 24),

                    // Contact Info Section
                    _buildSectionTitle(context, 'Aloqa ma\'lumotlari'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.phone, 'Telefon', user.telephoneNumber ?? '-'),
                    ]),
                    
                    const SizedBox(height: 24),

                    // Address Section
                    _buildSectionTitle(context, 'Manzil'),
                    const SizedBox(height: 8),
                    _buildInfoCard([
                      _buildInfoRow(Icons.public, 'Davlat', user.state ?? '-'),
                      _buildInfoRow(Icons.location_city, 'Viloyat', user.region ?? '-'),
                      _buildInfoRow(Icons.place, 'Tuman', user.districts ?? '-'),
                      _buildInfoRow(Icons.home, 'Manzil', user.address ?? '-'),
                    ]),

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
