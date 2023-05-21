import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_series_generator/src/generated/time_series_generator.dart';

part 'time_series_generator_event.dart';
part 'time_series_generator_state.dart';

class TimeSeriesGeneratorBloc
    extends Bloc<TimeSeriesGeneratorEvent, TimeSeriesGeneratorState> {
  StreamSubscription?
      dataGenerationSubscription; // Stream subscription to control data generation

  TimeSeriesGeneratorBloc()
      : super(TimeSeriesGeneratorState(current: CurrentTimeSeriesData())) {
    on<StartDataGeneration>(_onStartDataGeneration);
    on<StopDataGeneration>(_onStopDataGeneration);
    on<OnSubscribe>(_onSubscribe);
    on<OnUnsubscribe>(_onUnsubscribe);
    on<OnPublish>(_onPublish);
  }

  void _onStartDataGeneration(
      StartDataGeneration event, Emitter<TimeSeriesGeneratorState> emit) {
    final constants = <double>[];
    final amplitudes = <double>[];
    final initialPhases = <double>[];

    for (var toneConfig in event.toneConfigs) {
      final constant = 2 * pi * toneConfig.frequency / event.sampleRate;
      constants.add(constant);
      amplitudes.add(toneConfig.amplitude);
      initialPhases.add(toneConfig.initialPhase);
    }

    final intervalMicroseconds = (1000000 / event.sampleRate).round();
    var elapsedTime = 0;

    dataGenerationSubscription?.cancel(); // Cancel any existing subscription

    dataGenerationSubscription =
        Stream.periodic(Duration(microseconds: intervalMicroseconds))
            .listen((_) {
      elapsedTime += intervalMicroseconds; // Update elapsed time

      final timeSeriesData = CurrentTimeSeriesData()
        ..x = elapsedTime / 1000 // Convert to milliseconds
        ..y = generateYValue(elapsedTime, constants, amplitudes, initialPhases);

      if (!dataGenerationSubscription!.isPaused) {
        emit(state.copyWith(
            current: timeSeriesData)); // Send data to subscribers
      }
    });
  }

  void _onStopDataGeneration(
      StopDataGeneration event, Emitter<TimeSeriesGeneratorState> emit) {
    dataGenerationSubscription
        ?.cancel(); // Cancel the data generation subscription
  }

  double generateYValue(int currentTime, List<double> constants,
      List<double> amplitudes, List<double> initialPhases) {
    double yValue = 0;

    for (var t = 0; t < constants.length; t++) {
      final value =
          amplitudes[t] * sin(constants[t] * currentTime + initialPhases[t]);
      yValue += value;
    }

    return yValue;
  }

  void _onSubscribe(OnSubscribe event, Emitter<TimeSeriesGeneratorState> emit) {
    final updated = state.subscribers.map((e) => e).toList()..add(event.hash);

    emit(state.copyWith(subscribers: updated));
    print('Subscribed Event: ' + event.hashCode.toString());

    if (updated.length == 1 && state.isGenerating!) {
      add(StartDataGeneration(state.sampleRate!, state.toneConfigs!));
    }
  }

  void _onUnsubscribe(
      OnUnsubscribe event, Emitter<TimeSeriesGeneratorState> emit) {
    final updated = state.subscribers.map((e) => e).toList()
      ..remove(event.hashCode);

    emit(state.copyWith(subscribers: updated));
    print('Unsubscribed Event: ' + event.hashCode.toString());

    if (updated.length == 0) {
      add(StopDataGeneration());
    }
  }

  void _onPublish(OnPublish event, Emitter<TimeSeriesGeneratorState> emit) {
    emit(
      state.copyWith(
        sampleRate: event.sampleRate,
        toneConfigs: event.toneConfigs,
        isGenerating: true,
      ),
    );

    if (state.subscribers.length > 0) {
      // Start data generation if there are active subscribers
      add(StartDataGeneration(state.sampleRate!, state.toneConfigs!));
    }
  }

  @override
  Future<void> close() {
    dataGenerationSubscription
        ?.cancel(); // Cancel the subscription when closing the bloc
    return super.close();
  }
}
