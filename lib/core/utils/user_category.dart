import 'package:flutter/material.dart';

/// Utilidades de categoría de usuario basadas en el campo real `role` de la
/// colección `users` de Firestore.
///
/// Roles reales existentes en el proyecto (ver FIRESTORE_COLLECTIONS_GUIDE.md):
/// - user       → pasajero
/// - driver     → chofer
/// - tickeador  → encargado del control de pasajes
/// - admin      → administrador
/// - presidente → dirigente
///
/// NOTA: la colección `users` NO guarda categorías `student`/`adult` en
/// `role`, `category` ni `userType`; esas categorías existen solo en
/// `benefit_request.benefitType` (solicitudes de beneficio). Por eso no se
/// inventan roles ni colores para estudiante/adulto aquí.

/// Color del borde de categoría del usuario según su `role`.
Color getUserCategoryColor(String role) {
  switch (role) {
    case 'user':
      return const Color(0xFF00ACC1); // turquesa
    case 'driver':
      return const Color(0xFF7F1D1D); // rojo vino oscuro
    case 'tickeador':
      return const Color(0xFF0D1B2A); // azul casi negro
    case 'admin':
      return const Color(0xFF8E24AA); // morado
    case 'presidente':
      return const Color(0xFFE57373); // rojo suave
    default:
      return Colors.grey;
  }
}

/// Etiqueta legible de la categoría según el `role`.
String getUserCategoryLabel(String role) {
  switch (role) {
    case 'user':
      return 'Pasajero';
    case 'driver':
      return 'Chofer';
    case 'tickeador':
      return 'Tickeador';
    case 'admin':
      return 'Administrador';
    case 'presidente':
      return 'Dirigente';
    default:
      return role;
  }
}

/// Descripción corta de la categoría del usuario según su `role`.
String getUserCategoryDescription(String role) {
  switch (role) {
    case 'user':
      return 'Usuario pasajero de MiRuta';
    case 'driver':
      return 'Conductor registrado en MiRuta';
    case 'tickeador':
      return 'Encargado del control de pasajes';
    case 'admin':
      return 'Administrador del sistema';
    case 'presidente':
      return 'Responsable de gestión de rutas';
    default:
      return 'Usuario de MiRuta';
  }
}
