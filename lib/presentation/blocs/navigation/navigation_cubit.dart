import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  void changeTab(int index) {
    emit(state.copyWith(currentIndex: index));
  }

  void toggleDrawer() {
    emit(state.copyWith(isDrawerOpen: !state.isDrawerOpen));
  }

  void setDrawerState(bool isOpen) {
    emit(state.copyWith(isDrawerOpen: isOpen));
  }

  void showBottomSheet() {
    emit(state.copyWith(isBottomSheetVisible: true));
  }

  void hideBottomSheet() {
    emit(state.copyWith(isBottomSheetVisible: false));
  }
}