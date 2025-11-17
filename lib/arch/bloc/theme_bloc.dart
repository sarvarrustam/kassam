import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ToggleThemeEvent extends ThemeEvent {
  const ToggleThemeEvent();
}

class SetThemeEvent extends ThemeEvent {
  final bool isDarkMode;
  const SetThemeEvent(this.isDarkMode);

  @override
  List<Object> get props => [isDarkMode];
}

// States
abstract class ThemeState extends Equatable {
  final bool isDarkMode;
  const ThemeState(this.isDarkMode);

  @override
  List<Object> get props => [isDarkMode];
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.isDarkMode);
}

class ThemeChanged extends ThemeState {
  const ThemeChanged(super.isDarkMode);
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeInitial(false)) {
    on<ToggleThemeEvent>((event, emit) {
      final newMode = !state.isDarkMode;
      emit(ThemeChanged(newMode));
    });

    on<SetThemeEvent>((event, emit) {
      emit(ThemeChanged(event.isDarkMode));
    });
  }
}
