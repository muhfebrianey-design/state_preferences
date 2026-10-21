import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final bool isLoading;
  final bool isDarkMode; // Latihan 1
  final int visitCount; // Latihan 2
  final List<String> favorites; // Latihan 3
  final Future<void> Function(User) updateUser;
  final Future<void> Function() logout;
  final Future<void> Function() toggleTheme; // Latihan 1
  final Future<void> Function(String) addFavorite; // Latihan 3
  final Future<void> Function(String) removeFavorite; // Latihan 3

  const UserProvider({
    super.key,
    required this.user,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.updateUser,
    required this.logout,
    required this.toggleTheme,
    required this.addFavorite,
    required this.removeFavorite,
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  // Semua data yang dipakai UI harus ikut dicek di sini,
  // kalau tidak, widget tidak akan rebuild saat data itu berubah.
  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return oldWidget.user != user ||
        oldWidget.isLoading != isLoading ||
        oldWidget.isDarkMode != isDarkMode ||
        oldWidget.visitCount != visitCount ||
        oldWidget.favorites != favorites;
  }
}

class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    // Latihan 1: muat preferensi tema
    final isDark = prefs.getBool('is_dark_mode') ?? false;

    // Latihan 2: tambah counter setiap aplikasi dibuka
    final visits = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visits);

    // Latihan 3: muat daftar favorit
    final favs = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;
    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDark;
      _visitCount = visits;
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _updateUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    if (!mounted) return;
    setState(() {
      _user = newUser;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    if (!mounted) return;
    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  // Latihan 1
  Future<void> _toggleTheme() async {
    final newValue = !_isDarkMode;
    setState(() {
      _isDarkMode = newValue;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', newValue);
  }

  // Latihan 3
  Future<void> _addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty || _favorites.contains(value)) return;

    // Buat list BARU (bukan .add) supaya updateShouldNotify mendeteksi perubahan
    final newList = [..._favorites, value];
    setState(() {
      _favorites = newList;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', newList);
  }

  Future<void> _removeFavorite(String item) async {
    final newList = _favorites.where((e) => e != item).toList();
    setState(() {
      _favorites = newList;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', newList);
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode,
      visitCount: _visitCount,
      favorites: _favorites,
      updateUser: _updateUser,
      logout: _logout,
      toggleTheme: _toggleTheme,
      addFavorite: _addFavorite,
      removeFavorite: _removeFavorite,
      child: widget.child,
    );
  }
}