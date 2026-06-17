import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _buildAvatar(auth),

          if (auth.isAdmin) _buildAdminTile(context),

          const AppSectionTitle('Account'),
          const SizedBox(height: 8),

          AccountTile(
            title: 'Edit Profile',
            subtitle: 'Change your name or address',
            onTap: () => _showEditProfile(context, auth),
          ),

          AccountTile(
            title: 'Order History',
            subtitle: 'View your past orders',
            onTap: () => _showOrderHistory(context, auth),
          ),
          const SizedBox(height: 8),

          // Log out tile
          AccountTile(
            title: 'Log Out',
            onTap: () async => await auth.signOut(),
          ),

        ],
      ),
    );
  }


  Widget _buildAvatar(AuthProvider auth) {
    final firstLetter = (auth.displayName?.isNotEmpty == true)
        ? auth.displayName![0].toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [

          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.black,
            child: Text(
              firstLetter,
              style: GoogleFonts.montserrat(
                fontSize: 32,
                color: AppTheme.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            auth.displayName ?? '',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),

          Text(
            auth.currentEmail ?? '',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppTheme.grey,
            ),
          ),

          if (auth.isAdmin) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.15), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold), 
              ),
              child: Text(
                'ADMIN',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: AppTheme.gold),
        title: Text(
          'Admin Panel',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppTheme.white,
          ),
        ),
        subtitle: Text(
          'Manage products & orders',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AppTheme.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.white),

        onTap: () => context.push('/admin'),
      ),
    );
  }


  void _showEditProfile(BuildContext context, AuthProvider auth) {

    // Text controllers for the two input fields
    final nameCtrl = TextEditingController(text: auth.displayName ?? '');
    final addrCtrl = TextEditingController();
    final service  = FirestoreService();
    bool saving    = false;

    if (auth.currentUid != null) {
      service.getUserProfile(auth.currentUid!).then((data) {
        addrCtrl.text = data?['address'] ?? '';
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,      
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(


          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Edit Profile',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: nameCtrl,
                hint: 'Full Name',
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: addrCtrl,
                hint: 'Shipping Address',
                capitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              AppButton(
                loading: saving, 
                text: 'Save Changes',
                onPressed: () async {

                  // Show spinner
                  setState(() => saving = true);

                  final uid = auth.currentUid;
                  if (uid != null) {

                    await service.updateUserProfile(
                      uid,
                      name: nameCtrl.text.trim(),
                      address: addrCtrl.text.trim(),
                    );

                    await auth.refreshProfile();
                  }

                  // Hide spinner
                  setState(() => saving = false);

                  // Close sheet and show success message
                  // ctx.mounted check = make sure the sheet is still open
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _showOrderHistory(BuildContext context, AuthProvider auth) {

    final uid = auth.currentUid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,   
        maxChildSize: 0.95,      
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              Text(
                'Order History',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService().getOrders(uid),
                  builder: (_, snap) {

                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = snap.data!;

                    if (orders.isEmpty) {
                      return Center(
                        child: Text(
                          'No orders yet',
                          style: GoogleFonts.montserrat(color: AppTheme.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController, 
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => _buildOrderTile(orders[i]),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Widget _buildOrderTile(Map<String, dynamic> order) {

    final status = order['status'] ?? 'Processing';
    final total  = (order['total'] as num?)?.toDouble() ?? 0;
    final items  = (order['items'] as List?)?.length ?? 0;

    final statusColor = status == 'Delivered'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.orange;

    return ListTile(
      contentPadding: EdgeInsets.zero, 

      title: Text(
        'Order #${(order['id'] as String).substring(0, 6).toUpperCase()}',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),

      subtitle: Text(
        '$items item(s)  •  \$${total.toStringAsFixed(2)}',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          color: AppTheme.grey,
        ),
      ),

      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12), 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
      ),
    );
  }
}