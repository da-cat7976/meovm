import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meovm/meovm.dart';
import 'package:meovm_bloc/src/members/bloc.dart';

extension BlocMemberFactoryExtension on ViewModelMemberFactory {
  BlocMember<B, S> bloc<B extends StateStreamable<S>, S>({
    required BlocResolver<B, S> resolver,
    String? debugName,
  }) {
    return BlocMember<B, S>(
      resolver: resolver,
      debugName: debugName ?? 'BlocMember #${nextId()}',
    );
  }
}
