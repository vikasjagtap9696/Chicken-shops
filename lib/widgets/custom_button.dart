import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final double width;
  final double height;
  final bool isOutlined;
  final bool isSmall;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 55,
    this.isOutlined = false,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? Color(0xFFE64A19);
    final buttonTextColor = textColor ?? (isOutlined ? buttonColor : Colors.white);

    Widget button = isOutlined
        ? OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: buttonColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmall ? 8 : 16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 24,
          vertical: isSmall ? 12 : 16,
        ),
      ),
      child: _buildChild(buttonTextColor),
    )
        : ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: buttonTextColor,
        elevation: 5,
        shadowColor: buttonColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmall ? 8 : 16),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 24,
          vertical: isSmall ? 12 : 16,
        ),
        minimumSize: Size(width, height),
      ),
      child: _buildChild(buttonTextColor),
    );

    if (!isSmall) {
      button = SizedBox(width: width, height: height, child: button);
    }

    return button;
  }

  Widget _buildChild(Color buttonTextColor) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: buttonTextColor,
              strokeWidth: 2,
            ),
          ),
          if (!isSmall) ...[
            SizedBox(width: 12),
            Text(
              'लोडिंग...',
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 12 : 16,
                fontWeight: FontWeight.w600,
                color: buttonTextColor,
              ),
            ),
          ],
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSmall ? 16 : 20, color: buttonTextColor),
          SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: isSmall ? 12 : 16,
              fontWeight: FontWeight.w600,
              color: buttonTextColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: isSmall ? 12 : 16,
        fontWeight: FontWeight.w600,
        color: buttonTextColor,
      ),
    );
  }
}