part of 'call_cubit.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object> get props => [];
}

class CallInitial extends CallState {}

class CallLoading extends CallState {}

class CallLoaded extends CallState {
  final List<CallLog> calls;

  const CallLoaded(this.calls);

  @override
  List<Object> get props => [calls];
}

class CallError extends CallState {
  final String message;

  const CallError(this.message);

  @override
  List<Object> get props => [message];
}
