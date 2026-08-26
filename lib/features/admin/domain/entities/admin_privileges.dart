import 'package:equatable/equatable.dart';

class AdminPrivileges extends Equatable {
  final bool manageRoutesCreate;
  final bool manageRoutesEdit;
  final bool manageRoutesDelete;
  final bool manageUsersAccept;
  final bool manageUsersSuspend;
  final bool manageUsersDelete;
  final bool manageAdminsCreate;
  final bool manageAdminsEdit;
  final bool manageAdminsDelete;

  const AdminPrivileges({
    this.manageRoutesCreate = false,
    this.manageRoutesEdit = false,
    this.manageRoutesDelete = false,
    this.manageUsersAccept = false,
    this.manageUsersSuspend = false,
    this.manageUsersDelete = false,
    this.manageAdminsCreate = false,
    this.manageAdminsEdit = false,
    this.manageAdminsDelete = false,
  });

  factory AdminPrivileges.fromMap(Map<String, dynamic>? data) {
    final routes = _group(data, 'manage_routes');
    final users = _group(data, 'manage_users');
    final admins = _group(data, 'manage_admins');
    return AdminPrivileges(
      manageRoutesCreate: _value(routes, 'create'),
      manageRoutesEdit: _value(routes, 'edit'),
      manageRoutesDelete: _value(routes, 'delete'),
      manageUsersAccept: _value(users, 'accept'),
      manageUsersSuspend: _value(users, 'suspend'),
      manageUsersDelete: _value(users, 'delete'),
      manageAdminsCreate: _value(admins, 'create'),
      manageAdminsEdit: _value(admins, 'edit'),
      manageAdminsDelete: _value(admins, 'delete'),
    );
  }

  Map<String, dynamic> toMap() => {
    'manage_routes': {
      'create': manageRoutesCreate,
      'edit': manageRoutesEdit,
      'delete': manageRoutesDelete,
    },
    'manage_users': {
      'accept': manageUsersAccept,
      'suspend': manageUsersSuspend,
      'delete': manageUsersDelete,
    },
    'manage_admins': {
      'create': manageAdminsCreate,
      'edit': manageAdminsEdit,
      'delete': manageAdminsDelete,
    },
  };

  AdminPrivileges copyWith({
    bool? manageRoutesCreate,
    bool? manageRoutesEdit,
    bool? manageRoutesDelete,
    bool? manageUsersAccept,
    bool? manageUsersSuspend,
    bool? manageUsersDelete,
    bool? manageAdminsCreate,
    bool? manageAdminsEdit,
    bool? manageAdminsDelete,
  }) {
    return AdminPrivileges(
      manageRoutesCreate: manageRoutesCreate ?? this.manageRoutesCreate,
      manageRoutesEdit: manageRoutesEdit ?? this.manageRoutesEdit,
      manageRoutesDelete: manageRoutesDelete ?? this.manageRoutesDelete,
      manageUsersAccept: manageUsersAccept ?? this.manageUsersAccept,
      manageUsersSuspend: manageUsersSuspend ?? this.manageUsersSuspend,
      manageUsersDelete: manageUsersDelete ?? this.manageUsersDelete,
      manageAdminsCreate: manageAdminsCreate ?? this.manageAdminsCreate,
      manageAdminsEdit: manageAdminsEdit ?? this.manageAdminsEdit,
      manageAdminsDelete: manageAdminsDelete ?? this.manageAdminsDelete,
    );
  }

  static Map<String, dynamic> _group(Map<String, dynamic>? data, String key) {
    final group = data?[key];
    return group is Map<String, dynamic> ? group : <String, dynamic>{};
  }

  static bool _value(Map<String, dynamic> group, String key) =>
      group[key] == true;

  @override
  List<Object?> get props => [
    manageRoutesCreate,
    manageRoutesEdit,
    manageRoutesDelete,
    manageUsersAccept,
    manageUsersSuspend,
    manageUsersDelete,
    manageAdminsCreate,
    manageAdminsEdit,
    manageAdminsDelete,
  ];
}
