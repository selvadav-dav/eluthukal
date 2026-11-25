import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/access_service.dart';
import '../theme/app_colors.dart';

/// Popup asking the user to unlock content with a scratch code (from the
/// purchased book) or by paying online.
///
/// Returns true when content was unlocked, false/null when skipped.
Future<bool?> showUnlockContentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _UnlockContentDialog(),
  );
}

/// Shows the unlock dialog only if the current user has no access yet.
Future<void> ensureContentAccess(BuildContext context) async {
  if (await AccessService.instance.hasAccess()) return;
  if (!context.mounted) return;
  await showUnlockContentDialog(context);
}

class _UnlockContentDialog extends StatefulWidget {
  const _UnlockContentDialog();

  @override
  State<_UnlockContentDialog> createState() => _UnlockContentDialogState();
}

class _UnlockContentDialogState extends State<_UnlockContentDialog> {
  final _codeController = TextEditingController();
  bool _showPayment = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await AccessService.instance.redeemScratchCode(_codeController.text);
    if (!mounted) return;
    if (err == null) {
      _success();
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  Future<void> _pay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await AccessService.instance.purchase();
    if (!mounted) return;
    if (err == null) {
      _success();
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  void _success() {
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'பாடங்கள் திறக்கப்பட்டன! 🎉',
          style: GoogleFonts.catamaran(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.background,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.menu_book_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(
                'பாடங்களைத் திறக்கவும்',
                textAlign: TextAlign.center,
                style: GoogleFonts.catamaran(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _showPayment
                    ? 'ஆன்லைனில் பணம் செலுத்தி அனைத்து பாடங்களையும் பெறுங்கள்'
                    : 'புத்தகத்தில் உள்ள ஸ்கிராட்ச் குறியீட்டை உள்ளிடவும்',
                textAlign: TextAlign.center,
                style: GoogleFonts.catamaran(fontSize: 15, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              _buildToggle(),
              const SizedBox(height: 18),
              if (_showPayment) _buildPayment() else _buildScratch(),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.catamaran(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.playfulPink,
                  ),
                ),
              ],
              if (AccessService.sampleMode) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                  child: Text(
                    'பின்னர் (மாதிரி முறை)',
                    style: GoogleFonts.catamaran(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: _busy ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.catamaran(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          tab('ஸ்கிராட்ச் கோடு', Icons.qr_code_2_rounded, !_showPayment,
              () => setState(() { _showPayment = false; _error = null; })),
          tab('பணம் செலுத்து', Icons.payment_rounded, _showPayment,
              () => setState(() { _showPayment = true; _error = null; })),
        ],
      ),
    );
  }

  Widget _buildScratch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeController,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 3),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => _busy ? null : _redeem(),
        ),
        const SizedBox(height: 14),
        _actionButton('குறியீட்டைச் சரிபார்', AppColors.secondary, _redeem),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 2),
          ),
          child: Column(
            children: [
              Text(
                '₹${AccessService.priceInRupees}',
                style: GoogleFonts.catamaran(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'அனைத்து பாடங்கள், விளையாட்டுகள், வீடியோக்கள்',
                textAlign: TextAlign.center,
                style: GoogleFonts.catamaran(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _actionButton('இப்போது செலுத்து', AppColors.primary, _pay),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.catamaran(fontSize: 17, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}
