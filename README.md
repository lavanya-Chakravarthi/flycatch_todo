# Flutter ToDo Tracker

A **Flutter ToDo Tracker** application built with **offline-first principles** and **merge-safe data
handling**.  
The app is designed using **Clean Architecture** and **BLoC state management**, with features
optimized for performance, usability, and offline capability.

---

## Features

- **Offline-First & Auto Sync:**
    - Works seamlessly offline.
    - Automatic sync every 5 minutes with a fake API.
    - Manual sync via pull-to-refresh.
    - Displays sync status symbol and last update time.

- **CRUD Operations:**
    - Add, edit, delete, and update ToDos.
    - Update status: Pending or Completed.
    - Tap on a ToDo to view its **description in an AlertDialog**.

- **Theme Support:**
    - Light/Dark mode toggle.
    - Theme preference stored using `SharedPreferences`.

- **Optimized Data Handling:**
    - Local caching using `sqflite`.
    - ToDos listed in descending order of update and creation time.
    - Exception handling for cache failure, server failure, and other edge cases.

- **Responsive Design:**
    - UI adapts to different screen sizes using `MediaQuery`.

- **Architecture & State Management:**
    - Clean Architecture (separation of concerns).
    - BLoC + `equatable` for state management.
    - Optimized code for performance.

---

## 📂 Architecture Overview

The app is structured following **Clean Architecture**, with separation of concerns into three main
layers:

todo_tracker/
├── lib/
│ ├── core/ # constants, services, error handling,network info
│ ├── data/ # Models, repository implementations, local & remote data sources
│ ├── domain/ # Entities, use cases,repository
│ ├── presentation/ # Screens, widgets, BLoCs
│ ├── injections.dart # service locator for DI
│ └── main.dart # App entry point

**Flow:**

1. **Presentation Layer**: Flutter widgets & BLoCs handle UI and state.
2. **Domain Layer**: Business logic and entities.
3. **Data Layer**: Handles API requests (`http`) and local
   caching (`sqflite` + `path` + `path_provider`).

---

## 🛠️ Setup and Run Instructions

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.1+
- Android/iOS device or emulator

### Steps

## Clone the repository

git clone https://github.com/username/todo_tracker.git
cd todo_tracker

## Install dependencies

flutter pub get

## Run the app

flutter run

## Libraries Used

- **State Management & Architecture:**

  - flutter_bloc
  
  - equatable

- **Local Database & Storage:**

  - sqflite

  - path

  - path_provider

  - shared_preferences

- **Networking:**

  - http

  - connectivity_plus

- **UI & Responsiveness:**

  - MediaQuery for responsive design

  - AlertDialog for displaying ToDo descriptions

## Usage

- Add a new ToDo by tapping the “+” button.

- Edit or delete a ToDo using the options menu.

- Tap a ToDo to view its description in an AlertDialog.

- Toggle theme mode using the settings button.

- Pull down on the ToDo list to manually sync with the API.

- View sync status symbol and last update time under each ToDo.

