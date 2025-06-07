part of 'navigation_cubit.dart';

class NavigationState extends Equatable {
  final int currentIndex;
  final bool isDrawerOpen;
  final bool isBottomSheetVisible;

  const NavigationState({
    this.currentIndex = 0,
    this.isDrawerOpen = false,
    this.isBottomSheetVisible = false,
  });

  NavigationState copyWith({
    int? currentIndex,
    bool? isDrawerOpen,
    bool? isBottomSheetVisible,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      isBottomSheetVisible: isBottomSheetVisible ?? this.isBottomSheetVisible,
    );
  }

  @override
  List<Object> get props => [currentIndex, isDrawerOpen, isBottomSheetVisible];
}