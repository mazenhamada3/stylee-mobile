import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. FORM WIDGETS (Text Fields, Buttons, Headings)
// ═══════════════════════════════════════════════════════════════════════════

/// Reusable text input field with consistent STYLEE styling
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  final bool obscure;
  final int? maxLength;
  final TextCapitalization capitalization;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    required this.controller,
    required this.hint,
    this.type = TextInputType.text,
    this.obscure = false,
    this.maxLength,
    this.capitalization = TextCapitalization.none,
    this.suffix,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      maxLength: maxLength,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        hintStyle: GoogleFonts.montserrat(fontSize: 14, color: AppTheme.grey),
        border: OutlineInputBorder(borderSide: BorderSide.none),
        filled: true,
        fillColor: AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        counterText: '',
      ),
    );
  }
}

/// Primary call-to-action button (full width, loading state support)
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool loading;

  const AppButton({required this.onPressed, required this.text, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }
}

/// Section heading with consistent styling
class AppSectionTitle extends StatelessWidget {
  final String text;
  const AppSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. BRANDING WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// STYLEE brand logo with image fallback
class AppLogo extends StatelessWidget {
  final double height;
  const AppLogo({super.key, this.height = 92});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/STYLEE-removebg-preview.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'STYLEE',
        style: GoogleFonts.montserrat(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: AppTheme.gold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PRODUCT SELECTOR WIDGETS (Color & Size Pickers)
// ═══════════════════════════════════════════════════════════════════════════

/// Color selection circles with hex color support
class ColorSelector extends StatelessWidget {
  final List<String> colors;
  final String? selected;
  final void Function(String) onSelect;
  final Map<String, String>? hexMap;

  const ColorSelector({required this.colors, this.selected, required this.onSelect, this.hexMap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors.map((c) {
        final active = c == selected;
        final hex = hexMap?[c] ?? '#000000';
        return GestureDetector(
          onTap: () => onSelect(c),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
              shape: BoxShape.circle,
              border: Border.all(color: active ? AppTheme.gold : Colors.transparent, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Size selection buttons with stock indication and OUT OF STOCK labels
class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selected;
  final Map<String, int>? quantities;
  final void Function(String) onSelect;

  const SizeSelector({required this.sizes, this.selected, this.quantities, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((s) {
        final active = s == selected;
        final disabled = (quantities?[s] ?? 1) <= 0;
        return GestureDetector(
          onTap: disabled ? null : () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: disabled ? AppTheme.lightGrey.withOpacity(0.45) : (active ? AppTheme.black : AppTheme.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppTheme.black : AppTheme.lightGrey),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: disabled ? AppTheme.grey : (active ? AppTheme.white : AppTheme.black),
                    ),
                  ),
                  if (disabled)
                    Text(
                      'OUT',
                      style: GoogleFonts.montserrat(fontSize: 8, color: AppTheme.grey, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. CART WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Displays a single item in the shopping cart (full mode or read-only mode)
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onRemove;
  final bool showControls;

  const CartItemTile({
    required this.item,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image (64x64)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _CartItemImage(path: item.imagePath),
          ),
          const SizedBox(width: 12),

          // Product info (name, size/color, price)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.size} / ${item.color}',
                  style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          // Controls (quantity buttons + delete) OR just quantity text
          showControls
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: onRemove,
                      tooltip: 'Remove',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QtyButton(icon: Icons.remove, onTap: onDecrease),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _QtyButton(icon: Icons.add, onTap: onIncrease),
                      ],
                    ),
                  ],
                )
              : Text(
                  'x${item.quantity}',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                ),
        ],
      ),
    );
  }
}

/// Private helper: Handles both network and asset images for cart items
class _CartItemImage extends StatelessWidget {
  final String path;
  const _CartItemImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      path,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: AppTheme.lightGrey,
        child: const Icon(Icons.image_not_supported, color: AppTheme.grey, size: 24),
      );
}

/// Private helper: Circular + and - buttons for quantity adjustment
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.lightGrey),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. PROFILE/NAVIGATION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class AccountTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const AccountTile({required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: GoogleFonts.montserrat(fontSize: 11, color: AppTheme.grey))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
