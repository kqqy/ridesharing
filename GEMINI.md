# GEMINI.md: Ridesharing Flutter App

This document provides a comprehensive overview of the Ridesharing Flutter application, intended to serve as a technical and functional guide for developers.

## Project Overview

This is a mobile application for ridesharing, built using the Flutter framework and Dart. It connects drivers and passengers, allowing them to create, find, and manage shared trips. The backend is powered by Supabase, which handles user authentication, database storage, and other backend services.

### Core Features

*   **Dual User Roles:** The application supports two main user roles: 'Passenger' and 'Driver', each with a dedicated interface and functionality.
*   **Authentication:** User sign-up and login are handled via email and password, managed by Supabase Auth. New users go through a brief onboarding process to set their preferences.
*   **Trip Management:**
    *   **Passengers:** Can create new trip requests, browse and join existing open trips, view upcoming trips, and see their trip history.
    *   **Drivers:** Can view passenger trip requests, manage their own active trips, and see their trip history.
*   **Real-time & Location:** The app uses Google Maps for displaying routes, `geolocator` for location tracking, and `flutter_polyline_points` to draw routes on the map.
*   **In-Trip Features:** Includes an in-trip chat for communication and an SOS feature for drivers in case of emergencies.
*   **Rating System:** After a trip is completed, users are prompted to rate each other.

### Architecture

*   **Frontend:** Flutter (Dart)
*   **Backend:** Supabase (Authentication, PostgreSQL Database)
*   **UI Structure:** The UI is organized by feature/page (e.g., `auth_page`, `passenger_home`, `driver_home`). UI presentation is often separated from logic using dedicated widget files (e.g., `auth_widgets.dart`, `passenger_widgets.dart`).
*   **State Management:** State management appears to be handled locally within widgets using `StatefulWidget` and `setState`.
*   **Data Model:** The core data is structured around the `Trip` model (`lib/trip_model.dart`), which is consistent with the `trips` table schema in the Supabase database.

## Key Files

*   `pubspec.yaml`: Defines the project's dependencies, including `supabase_flutter`, `google_maps_flutter`, `geolocator`, and others.
*   `lib/main.dart`: The application's entry point. Initializes Supabase and sets the initial route to `AuthPage`.
*   `lib/auth_page.dart`: Manages user authentication (login/registration) and the initial user profile setup.
*   `lib/home_page.dart`: The main landing page after login, which acts as a role switcher between 'Passenger' and 'Driver'.
*   `lib/passenger_home.dart`: The primary screen for passengers, showing available trips and providing access to trip creation and management.
*   `lib/driver_home.dart`: The primary screen for drivers, showing active trip details and trip requests.
*   `lib/trip_model.dart`: Defines the `Trip` data class, representing the structure of a trip record.
*   `lib/passenger_create_trip_page.dart`: The page where passengers input details to create a new trip request.

## Building and Running

### Prerequisites

*   Flutter SDK installed.
*   A configured Supabase project (the URL and anonKey are currently hardcoded in `lib/main.dart`).

### Commands

1.  **Install Dependencies:**
    Open a terminal in the project root and run:
    ```bash
    flutter pub get
    ```

2.  **Run the Application:**
    Connect a device or start an emulator, then run:
    ```bash
    flutter run
    ```

3.  **Run Tests:**
    To execute unit tests (Note: no `test` directory currently exists, but this is the standard command):
    ```bash
    flutter test
    ```

## Development Conventions

*   **File Naming:** Files are named using `snake_case`.
*   **UI/Logic Separation:** Logic is generally contained within `State` classes, while the UI layout is built in the `build` method. Widgets are often extracted into separate files for reusability (e.g., `passenger_widgets.dart`).
*   **Backend Interaction:** All Supabase interactions are performed using the global `supabase` client instance defined in `lib/main.dart`.
*   **Data Serialization:** The `Trip.fromMap()` factory method is used to convert database records (Map) into strongly-typed Dart objects.
