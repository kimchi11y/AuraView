# 🎬 AuraView

A Flutter-based mobile app that helps friends and couples choose a movie to watch together when hanging out — simply swipe on movies you like, and AuraView finds the ones you *both* love.

---

## 👥 Group Information

Name (Matric Number)
1. ABDUL HAKIM BIN ABD. RAZAK (2313945)
2. FARIS BIN SUHAIMI (2317561)
3. ABU MARWAN BIN ABU ZAKIE (2221579)
4. MUHAMMAD ALIF ZAKWAN BIN MOHD SHUKRI (2312225)

---

## 📋 Tasks Assigned for Each Group Member

## 👥 Updated Workload Breakdown (Firebase Edition)

### ALIF: Auth, Onboarding & User Profiles

*Focuses on Firebase project initialization, user creation, and profile setup.*

* **UI/Frontend Tasks:**
  * Splash screen, Sign-up, and Login screens.
  * Profile Screen with avatar image picker and upload capability.

* **Firebase Tasks (Owns `USERS` Firestore collection):**
  * Integrating the `firebase_auth` package (Email/Password registration, login, logout).
  * Setting up `firebase_storage` to handle user avatar image uploads and retrieving the download URLs.
  * Creating the user document in the `users` Firestore collection upon signup.

---

### HAKIM: Swipe Engine & Match Logic

*Focuses on the core Tinder-style swipe mechanics and immediate match validation.*

* **UI/Frontend Tasks:**
  * Tinder-style swipe card widget with smooth gesture detection.
  * Right/left swipe logic, card animations, and deck preloading.
  * Match celebration overlay screen.

* **Firebase Tasks (Owns `SWIPES` & `MATCHES` Firestore collections):**
  * Writing swipe data to the `swipes` Firestore collection.
  * **Match Detection Logic:** Implementing a Firestore transaction or query when a user swipes right. It checks if a document already exists in `swipes` where `fromUserId` is the *other* user and `liked` is `true`. If yes, it creates a new document in the `matches` collection.

---

### ABU: Movie Data, API Integration & Caching

*Focuses on fetching movie data from TMDB/IMDb, filtering, and caching.*

* **UI/Frontend Tasks:**
  * Filter bottom sheet UI (genre, year, rating).
  * Infinite scroll/paginated loading pagination for the swipe deck.

* **Firebase Tasks (Owns `MOVIES_CACHE` Firestore collection):**
  * Integrating the TMDB/IMDb HTTP API service inside Flutter.
  * **Caching Layer:** Writing fetched movies into a local cache (using a package like `hive` or `sqflite`) or storing popular movie metadata into a `movies_cache` Firestore collection so the app doesn't hit TMDB rate limits.

---

### FARIS: Social Network, Friends & Push Notifications

*Focuses on connecting users together and alerting them using Firebase's cloud network.*

* **UI/Frontend Tasks:**
  * Search Username screen + real-time Firestore query.
  * Friends list screen with status badges (Pending, Friends).
  * Shared matches feed (fetching documents from the `matches` collection where the current user and their selected friend are both participants).

* **Firebase Tasks (Owns `FRIEND_REQUESTS` & `FRIENDSHIPS` Firestore collections):**
  * Managing the state transitions in Firestore for `friend_requests` and `friendships`.
  * **Push Notifications:** Setting up `firebase_messaging` (FCM). Using the `fcmTokens` array from the `users` collection to send push notifications when someone receives a friend request or triggers a new movie match.

---

## 💡 1. Project Ideation & Initiation

### 1.1 App Details

**a. Title**

AuraView

**b. Background of the Problem**

Choosing a movie to watch together is one of the most common sources of friction when friends or couples hang out. One person wants action, the other wants rom-com; scrolling endlessly through streaming catalogues leads to decision fatigue and wasted time. Existing solutions (group chats, streaming watch-party features) lack a simple, fun mechanism to surface movies that *both* parties genuinely want to watch. AuraView solves this by letting each person independently swipe on movies they like, then automatically revealing only the movies they *both* swiped right on — eliminating the back-and-forth and making movie night decisions instant and enjoyable.

**c. Purpose or Objective**

To help friends and couples quickly and effortlessly pick a movie they both like by providing a Tinder-style swiping experience where mutual right-swipes produce a shared match list, removing the guesswork and arguments from movie selection.

**d. Target User**

- **Primary:** Friends and couples (ages 16–35) who regularly watch movies together during hangouts, dates, or casual nights in.
- **Secondary:** Any small group (2–4 people) looking for a fun, low-effort way to agree on what to watch.

**e. Preferred Platform**

- **Primary:** Smartphones (iOS & Android) via Flutter.
- **Secondary (future consideration):** Wearables (e.g., Apple Watch, Wear OS) for match notifications.

**f. Features and Functionalities**

1. User Authentication (Email/Password sign-up and login via Firebase Auth).
2. User Profile Management (avatar upload, bio).
3. Tinder-style Swipe Deck — each user independently swipes right (like) or left (skip) on movies.
4. Movie Filtering (genre, year, rating) so users can narrow down the pool before swiping.
5. **Mutual Match Detection** — when both connected users like the same movie, it appears in a shared "Matched" list in real time.
6. Friend/Partner Connection system — users link their accounts so the app compares swipes.
7. Shared Matches Feed — a unified screen showing only the movies both users liked.
8. Push Notifications via FCM — alerts when a new mutual match is found or a connection request is received.
9. Cached movie data (local + Firestore) to minimize external TMDB API calls and reduce latency.

### 1.2 Rationale (Why & How)

**Why:**  
The idea came from real-life experiences of spending more time scrolling through Netflix than actually watching a movie when with friends or a partner. Most streaming platforms surface content based on individual algorithms, not shared preferences. There is no simple tool that cross-references two people's tastes and returns only the overlap. AuraView fills that gap by turning preference-matching into a quick, gamified swipe session.

**How:**  
The concept was developed through group brainstorming and observing common user frustrations on streaming platforms and social media (e.g., "we spent 40 minutes choosing a movie and then went to sleep"). The team analysed how dating-app swipe mechanics could be repurposed for content discovery, and how Firebase's real-time capabilities could power instant mutual-match detection between two users.

---

## 📐 2. Requirement Analysis & Planning

### 2.1 Technical Feasibility & Back-end Assessment

**Data Storage & CRUD Operations:**

| Firestore Collection   | Create | Read | Update | Delete |
|------------------------|:------:|:----:|:------:|:------:|
| `users`                | ✅     | ✅   | ✅     | ✅     |
| `swipes`               | ✅     | ✅   | —      | —      |
| `matches`              | ✅     | ✅   | —      | —      |
| `movies_cache`         | ✅     | ✅   | —      | —      |
| `friend_requests`      | ✅     | ✅   | ✅     | ✅     |
| `friendships`          | ✅     | ✅   | —      | ✅     |

**Packages & Plugins:**

- `firebase_core` — Firebase initialization
- `firebase_auth` — Email/password authentication
- `cloud_firestore` — NoSQL database for all collections
- `firebase_storage` — Avatar image storage
- `firebase_messaging` — Push notifications via FCM
- `flutter_card_swiper` — Tinder-style swipe card widget with gesture detection
- `http` or `dio` — TMDB/IMDb API integration
- `hive` or `sqflite` — Local on-device caching
- `image_picker` — Avatar selection
- `cached_network_image` — Image caching for movie posters

**Platform Compatibility:**

- **Smartphones:** Fully supported on iOS 13+ and Android API 21+ (Flutter target).
- **Wearables:** Push notification delivery via companion apps. Full wearable UI is out of scope for the initial release but FCM notifications will appear on connected wearables.

### 2.2 Logical Design

**Sequence Diagram:**  
[A placeholder for your sequence diagram — e.g., an image or Mermaid diagram showing the flow of a user swiping right, the match detection logic, and the resulting match creation in Firestore.]

**Screen Navigation Flow:**

```
[Splash Screen]
      │
      ▼
[Login Screen] ──── [Sign-up Screen]
      │                    │
      ▼                    ▼
[Home / Swipe Deck] ◄──── [Profile Screen]
      │
      ├── [Filter Bottom Sheet]
      ├── [Match Celebration Overlay]
      ├── [Friends List Screen]
      │        │
      │        ├── [Search Username Screen]
      │        └── [Shared Matches Feed]
      └── [Push Notifications]
```

### 2.3 Gantt Chart & Timeline

| Stage                    | Start Date    | End Date      | Duration |
|--------------------------|---------------|---------------|----------|
| Project Initiation       | [YYYY-MM-DD]  | [YYYY-MM-DD]  | X days   |
| Requirement Analysis     | [YYYY-MM-DD]  | [YYYY-MM-DD]  | X days   |
| Design                   | [YYYY-MM-DD]  | [YYYY-MM-DD]  | X days   |
| Development              | [YYYY-MM-DD]  | [YYYY-MM-DD]  | X days   |
| Testing & Deployment     | [YYYY-MM-DD]  | [YYYY-MM-DD]  | X days   |
| Group Project Presentation | [YYYY-MM-DD] | [YYYY-MM-DD]  | 1 day    |

