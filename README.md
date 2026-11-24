# Pawtopia

Pawtopia is a cross-platform Flutter app for pet adoption and rescue, connecting adopters, shelters and admins on one platform.

## Features

- **Adoption marketplace:** browse pets with filters and favorites, and submit adoption requests; shelters manage pet listings and requests with full CRUD workflows.
- **Roles:** role-based access control across adopter, shelter and admin roles.
- **Real-time chat:** in-app chat between adopters and shelters.
- **Notifications:** push notifications via Firebase Cloud Messaging and local notifications.
- **AI-assisted missing-pet matching:** on-device MobileNet-v2 image embeddings (TFLite) with cosine similarity to match photos of missing pets.

## Tech Stack

- **Flutter / Dart** (Dart SDK ^3.10.3), Material Design
- **State management & DI:** Riverpod, get_it, go_router
- **Backend:** Firebase Authentication (email + Google sign-in), Cloud Firestore, Cloud Storage, Cloud Messaging
- **ML on device:** tflite_flutter with a MobileNet-v2 model (`assets/models/MobileNet-v2.tflite`)
- **Architecture:** clean data / domain / presentation layers with repository interfaces and failure handling (dartz)

## Project Structure

```
lib/
  app.dart, main.dart, bootstrap.dart
  config/        Firebase options
  core/          constants, theme, routing, services, DI, shared widgets
  data/          repository implementations
  domain/        repository contracts
```

## Getting Started

1. Install Flutter with Dart SDK 3.10.3 or newer.
2. Clone the repo and open `flutter_application_1/`.
3. Run `flutter pub get`.
4. Run `flutter run` on an Android or iOS device/emulator.

Firebase configuration is included in `lib/config/firebase_options.dart`.

## Screenshots

(Coming soon)
