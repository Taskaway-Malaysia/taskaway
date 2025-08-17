// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userApplicationForTaskHash() =>
    r'e937e78be62888e07a84bc28fc74395b1d6d0f48';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userApplicationForTask].
@ProviderFor(userApplicationForTask)
const userApplicationForTaskProvider = UserApplicationForTaskFamily();

/// See also [userApplicationForTask].
class UserApplicationForTaskFamily extends Family<AsyncValue<Application?>> {
  /// See also [userApplicationForTask].
  const UserApplicationForTaskFamily();

  /// See also [userApplicationForTask].
  UserApplicationForTaskProvider call(
    String taskId,
  ) {
    return UserApplicationForTaskProvider(
      taskId,
    );
  }

  @override
  UserApplicationForTaskProvider getProviderOverride(
    covariant UserApplicationForTaskProvider provider,
  ) {
    return call(
      provider.taskId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userApplicationForTaskProvider';
}

/// See also [userApplicationForTask].
class UserApplicationForTaskProvider
    extends AutoDisposeFutureProvider<Application?> {
  /// See also [userApplicationForTask].
  UserApplicationForTaskProvider(
    String taskId,
  ) : this._internal(
          (ref) => userApplicationForTask(
            ref as UserApplicationForTaskRef,
            taskId,
          ),
          from: userApplicationForTaskProvider,
          name: r'userApplicationForTaskProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userApplicationForTaskHash,
          dependencies: UserApplicationForTaskFamily._dependencies,
          allTransitiveDependencies:
              UserApplicationForTaskFamily._allTransitiveDependencies,
          taskId: taskId,
        );

  UserApplicationForTaskProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.taskId,
  }) : super.internal();

  final String taskId;

  @override
  Override overrideWith(
    FutureOr<Application?> Function(UserApplicationForTaskRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserApplicationForTaskProvider._internal(
        (ref) => create(ref as UserApplicationForTaskRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        taskId: taskId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Application?> createElement() {
    return _UserApplicationForTaskProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserApplicationForTaskProvider && other.taskId == taskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserApplicationForTaskRef on AutoDisposeFutureProviderRef<Application?> {
  /// The parameter `taskId` of this provider.
  String get taskId;
}

class _UserApplicationForTaskProviderElement
    extends AutoDisposeFutureProviderElement<Application?>
    with UserApplicationForTaskRef {
  _UserApplicationForTaskProviderElement(super.provider);

  @override
  String get taskId => (origin as UserApplicationForTaskProvider).taskId;
}

String _$applicationControllerHash() =>
    r'274d43469f07e74dea2c75297884aa9d02d82464';

/// See also [ApplicationController].
@ProviderFor(ApplicationController)
final applicationControllerProvider =
    AutoDisposeAsyncNotifierProvider<ApplicationController, void>.internal(
  ApplicationController.new,
  name: r'applicationControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$applicationControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ApplicationController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
