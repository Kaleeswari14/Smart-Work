import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";

class TimerState {
  final int secondsElapsed;
  final bool isRunning;
  final bool isPaused;
  final String? selectedWork;

  const TimerState({
    this.secondsElapsed = 0,
    this.isRunning = false,
    this.isPaused = false,
    this.selectedWork,
  });

  TimerState copyWith({
    int? secondsElapsed,
    bool? isRunning,
    bool? isPaused,
    String? selectedWork,
  }) {
    return TimerState(
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      selectedWork: selectedWork ?? this.selectedWork,
    );
  }

  String get formattedTime {
    final hours = (secondsElapsed ~/ 3600).toString().padLeft(2, "0");
    final minutes = ((secondsElapsed % 3600) ~/ 60).toString().padLeft(2, "0");
    final seconds = (secondsElapsed % 60).toString().padLeft(2, "0");
    return "$hours:$minutes:$seconds";
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(() => TimerNotifier());

class TimerNotifier extends Notifier<TimerState> {
  Timer? _ticker;

  @override
  TimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const TimerState();
  }

  void selectWork(String? work) {
    state = state.copyWith(selectedWork: work);
  }

  void startTimer() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: true, isPaused: false);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(secondsElapsed: state.secondsElapsed + 1);
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  void resumeTimer() {
    startTimer();
  }

  void stopTimer() {
    _ticker?.cancel();
    state = state.copyWith(isRunning: false, isPaused: false);
  }

  void resetTimer() {
    _ticker?.cancel();
    state = state.copyWith(secondsElapsed: 0, isRunning: false, isPaused: false);
  }
}
