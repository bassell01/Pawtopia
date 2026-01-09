class AppRoutes {
  static const authGate = '/';

  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Main
  static const home = '/home';
  static const pets = '/pets';
  static const favorites = '/favorites';
  static const aiMatching = '/ai-matching';
  static const profile = '/profile';
  static const uiKit = '/ui-kit';
  static const notifications = '/notifications';

  // Chat
  static const chat = '/chat';
  static const chatThread = '/chat/thread/:id';
  static String chatThreadPath(String id) => '/chat/thread/$id';

  // Adoption
  static const adoptionForm = '/adoption-form';
  static const myRequests = '/my-requests';
  static const incomingRequests = '/incoming-requests';

  // Admin
  static const adminDashboard = '/admin';

  // Pets
  static const addPet = '/pets/add';
  static const petDetails = '/pets/:id';
  static String petDetailsPath(String id) => '/pets/$id';
}
