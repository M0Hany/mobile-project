import 'package:rxdart/rxdart.dart';

abstract class BaseState<T> {
  final BehaviorSubject<T> _stateSubject = BehaviorSubject<T>();

  Stream<T> get state => _stateSubject.stream;
  T get currentState => _stateSubject.value;

  void updateState(T newState) {
    _stateSubject.add(newState);
  }

  void dispose() {
    _stateSubject.close();
  }
}
