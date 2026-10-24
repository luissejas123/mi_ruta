import 'package:equatable/equatable.dart';

abstract class PresidentePanelEvent extends Equatable {
  const PresidentePanelEvent();

  @override
  List<Object?> get props => [];
}

class LoadPresidentePanel extends PresidentePanelEvent {
  const LoadPresidentePanel();
}
