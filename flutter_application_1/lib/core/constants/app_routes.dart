class AppRoutes {
  // ✅ Root gate (AuthGate decides where to go)
  static const authGate = '/';

  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Shell / main
  static const home = '/home';
  static const pets = '/pets';
  static const favorites = '/favorites';
  static const chat = '/chat';
  static const profile = '/profile';
  static const uiKit = '/ui-kit';

  // // Adoption
  // static const adoptionForm = '/adoption-form';
  // static const myRequests = '/my-requests';
  // static const incomingRequests = '/incoming-requests';


  // Admin
  static const adminDashboard = '/admin';

 // Add Pet
  static const addPet = '/pets/add';
  
  //pets
  
  // Pets details
  static const petDetails = '/pets/:id';
  // ✅ helpers
  static String petDetailsPath(String id) => '/pets/$id';
}
