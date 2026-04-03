import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../services/api_client.dart';
import '../config/api_config.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  List<RoleModel> _roles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  List<RoleModel> get roles => _roles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiClient _apiClient = ApiClient();

  // Fetch all users
  Future<void> fetchUsers() async {
    debugPrint('DEBUG: fetchUsers() CALLED');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/users/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        debugPrint('DEBUG: Received users data: $data');
        _users = data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to fetch users';
      }
    } catch (e) {
      _errorMessage = 'Error fetching users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all roles
  Future<void> fetchRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/roles/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        _roles = data.map((json) => RoleModel.fromJson(json)).toList();
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to fetch roles';
      }
    } catch (e) {
      _errorMessage = 'Error fetching roles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new user
  Future<bool> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/users/', data: userData);
      if (response.statusCode == 201) {
        await fetchUsers(); // Refresh list
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to create user';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update role permissions
  Future<bool> updateRolePermissions(int roleId, List<Map<String, dynamic>> permissions) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put(
        '/roles/$roleId/permissions/',
        data: {'permissions': permissions},
      );
      if (response.statusCode == 200) {
        await fetchRoles(); // Refresh roles
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to update permissions';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating permissions: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user
  Future<bool> updateUser(int userId, Map<String, dynamic> userData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.put('/users/$userId/', data: userData);
      if (response.statusCode == 200) {
        await fetchUsers(); // Refresh list
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to update user';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle user status
  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    try {
      final response = await _apiClient.put(
        '/users/$userId/',
        data: {'is_active': isActive},
      );
      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
