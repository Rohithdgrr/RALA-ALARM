import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontService {
  static TextTheme getTextTheme(String fontFamily) {
    switch (fontFamily) {
      case 'Inter':
        return GoogleFonts.interTextTheme();
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme();
      case 'Roboto':
        return GoogleFonts.robotoTextTheme();
      case 'Montserrat':
        return GoogleFonts.montserratTextTheme();
      case 'Lato':
        return GoogleFonts.latoTextTheme();
      case 'Open Sans':
        return GoogleFonts.openSansTextTheme();
      default:
        return GoogleFonts.interTextTheme();
    }
  }

  static TextStyle getFont(String fontFamily, {double? size, FontWeight? weight, Color? color}) {
    switch (fontFamily) {
      case 'Inter':
        return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
      case 'Poppins':
        return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);
      case 'Roboto':
        return GoogleFonts.roboto(fontSize: size, fontWeight: weight, color: color);
      case 'Montserrat':
        return GoogleFonts.montserrat(fontSize: size, fontWeight: weight, color: color);
      case 'Lato':
        return GoogleFonts.lato(fontSize: size, fontWeight: weight, color: color);
      case 'Open Sans':
        return GoogleFonts.openSans(fontSize: size, fontWeight: weight, color: color);
      default:
        return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
    }
  }

  static List<String> get availableFonts => [
    'Inter',
    'Poppins',
    'Roboto',
    'Montserrat',
    'Lato',
    'Open Sans',
  ];
}
