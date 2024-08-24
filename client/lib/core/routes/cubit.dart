import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class RouterCubitState extends Equatable {
  final String? currentUrl;

  const RouterCubitState({this.currentUrl});

  @override
  List<Object?> get props => [currentUrl];
}

class RouterCubit extends Cubit<RouterCubitState> {
  RouterCubit() : super(const RouterCubitState(currentUrl: null));

  void setCurrentUrl(String? url) => emit(RouterCubitState(currentUrl: url));
}
