import 'package:flutter/material.dart';

/// Basemap URLs that work on Flutter web production hosts (Firebase, etc.).
///
/// The default OSM tile server blocks many hosted web apps. CARTO basemaps are
/// CORS-friendly and do not require an API key for admin dashboards.
abstract final class LocationMapTiles {
  static const userAgentPackageName = 'com.bimobond.admin.dashboard';
  static const maxNativeZoom = 19;
  static const maxZoom = 20.0;

  static String urlTemplateFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
  }

  static const attributionLabel = '© OpenStreetMap · © CARTO';
}
