import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "timer_provider.dart";

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("timer")),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Text(
                context.tr("session_timer"),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr("timer_description"),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Work Selection Dropdown Placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      timerState.selectedWork ?? context.tr("select_work_hint"),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "work_placeholder",
                        child: Text("Empty - Works will load from Supabase"),
                      ),
                    ],
                    onChanged: (val) {
                      // Placeholder
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Timer Display Dial
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: timerState.isRunning
                          ? [const Color(0xFF0D9488), const Color(0xFF1E3A8A)]
                          : [Colors.grey.shade100, Colors.grey.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: timerState.isRunning
                            ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 32,
                            color: timerState.isRunning
                                ? const Color(0xFF0D9488)
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timerState.formattedTime,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: timerState.isRunning
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timerState.isRunning
                                ? context.tr("timer_running")
                                : (timerState.isPaused
                                    ? context.tr("timer_paused")
                                    : context.tr("timer_stopped")),
                            style: TextStyle(
                              fontSize: 11,
                              color: timerState.isRunning
                                  ? const Color(0xFF0D9488)
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!timerState.isRunning && !timerState.isPaused) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(context.tr("start_timer")),
                        onPressed: () {
                          timerNotifier.startTimer();
                        },
                      ),
                    ),
                  ] else ...[
                    if (timerState.isRunning) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.pause),
                          label: Text(context.tr("pause_timer")),
                          onPressed: () {
                            timerNotifier.pauseTimer();
                          },
                        ),
                      ),
                    ] else if (timerState.isPaused) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(context.tr("resume_timer")),
                          onPressed: () {
                            timerNotifier.resumeTimer();
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.stop),
                        label: Text(context.tr("stop_timer")),
                        onPressed: () {
                          timerNotifier.stopTimer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Logged: ${timerState.formattedTime}. Save to DB will activate in Phase 4.",
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              if (timerState.secondsElapsed > 0 && !timerState.isRunning) ...[
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(context.tr("reset_timer")),
                  onPressed: () {
                    timerNotifier.resetTimer();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
