import 'package:flutter/material.dart';

const _allItems = [
  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
  BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Billetera'),
  BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Rutas'),
  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
];

/// Barra de navegación compartida. [currentIndex]/el índice que recibe
/// [onTap] siempre son el índice semántico de siempre (0=Inicio,
/// 1=Billetera, 2=Rutas, 3=Perfil) — igual sin importar cuántas pestañas se
/// muestren, así que [navigateBottomNav] no necesita saber si algún perfil
/// ocultó alguna.
///
/// [tabs] permite mostrar solo un subconjunto de esos 4 índices — hoy lo
/// usan Tickeador (sin Billetera ni Rutas, Figma "Modo Tickeador") y Admin
/// (su propia "Rutas" es Gestión de rutas, no la del pasajero). Por
/// defecto son las 4 — ningún llamador existente (pasajero/presidente/
/// chofer) cambia de comportamiento.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<int> tabs;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.tabs = const [0, 1, 2, 3],
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: tabs.indexOf(currentIndex).clamp(0, tabs.length - 1),
      onTap: (position) => onTap(tabs[position]),
      type: BottomNavigationBarType.fixed,
      items: [for (final i in tabs) _allItems[i]],
    );
  }
}