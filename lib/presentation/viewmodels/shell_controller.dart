import 'package:flutter/material.dart';

class ShellController extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isWriting = false;
  bool _isSidebarCollapsed = false;

  int get currentIndex => _currentIndex;
  bool get isWriting => _isWriting;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void setWriting(bool writing) {
    if (_isWriting == writing) return;
    _isWriting = writing;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }
}
