# AuraView

**Group Name:** Quesillo

**Repo:** https://github.com/kimchi11y/AuraView.git

### Group Members

| Name | Matric No | Assigned Tasks |
|---|---|---|
| Abdul Hakim Bin Abd. Razak | 2313945 | Swipe engine, match logic |
| Faris Bin Suhaimi | 2317561 | Friends system, shared matches, FCM notifications |
| Abu Marwan Bin Abu Zakie | 2221579 | TMDB API integration, movie model, data caching |
| Muhammad Alif Zakwan Bin Mohd Shukri | 2312225 | Firebase auth, onboarding, user profiles |

---

## Introduction

AuraView is a movie selection app built with Flutter. The idea behind it is simple — instead of scrolling endlessly through streaming catalogues and arguing over what to watch, friends and couples each swipe independently on movies they like, and AuraView automatically reveals only the movies they *both* swiped right on.

Everything is connected to Firebase, so swipes and matches are synced in real time, which means two people can swipe on their own phones and see the shared matches update as soon as both have liked the same movie.

We chose to build this as a mobile app because most people browse content and make plans from their phone. A quick swipe session takes less than a minute and fits naturally into how friends already decide what to do together.

## Problem Statement

Choosing a movie to watch together is one of the most common sources of friction when friends or couples hang out. One person wants action, the other wants rom-com; scrolling endlessly through streaming catalogues leads to decision fatigue and wasted time. Existing solutions — group chats, streaming watch-party features — lack a simple, fun mechanism to surface movies that *both* parties genuinely want to watch.

People end up spending more time choosing than actually watching, or one person just gives in and picks something they don't really want to see. There is no simple tool that cross-references two people's tastes and returns only the overlap.

AuraView solves this by letting each person independently swipe on movies they like, then automatically revealing only the films they *both* swiped right on — eliminating the back-and-forth and making movie night decisions instant and enjoyable.

## Objective

- Help friends and couples quickly pick a movie they both like through a Tinder-style swiping experience.
- Automatically surface mutual matches so there is no guesswork or arguing over what to watch.
- Keep everything synced in real time across two connected users through Firebase.
- Keep the app simple and fun so there is almost no learning curve.

## Target Users & Platform

- **Target users:** Friends and couples who regularly watch movies together during hangouts, dates, or casual nights in.
- **Platform:** Android and iOS (built with Flutter).

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend as a Service:** Firebase (Authentication, Cloud Firestore, Storage)
- **External API:** TMDB (The Movie Database)
- **Swipe UI:** flutter_card_swiper
- **State management:** setState with service-layer pattern

---

## Member Contributions


### Abdul Hakim Bin Abd. Razak – 2313945

**What I worked on:** The Tinder-style swipe engine and real-time match detection logic.

**Details:**

**1. Swipe deck and gesture handling.** The core of the app is the swipe interface, built using the `flutter_card_swiper` package. I set up the card swiper in `lib/screens/movie_swipe/discover_screen.dart` with smooth left/right gesture detection. Swiping right means "like" and swiping left means "skip," with visual indicators showing the swipe direction as the card moves. The deck is backed by movie data fetched from TMDB, so each card shows the poster, title, rating, and a brief overview.

**2. Match detection logic.** When a user swipes right on a movie, it writes a document to the `swipes` Firestore collection. Before writing, the match detection logic (`lib/services/swipe_service.dart`) queries whether the *other* connected user has already liked the same movie. If they have, it creates a new document in the `matches` collection, which triggers the match celebration overlay. I built the overlay widget (`lib/widgets/match_overlay.dart`) as a full-screen animation that pops up with the matched movie's poster and a celebratory message — this was one of the most rewarding parts to see working.

**Problems faced:**

- *Card swiper not resetting after swiping through all cards* — I had to reload the movie deck from TMDB when the user exhausted all cards, which meant handling empty states and showing a refresh prompt.
- *Match detection timing* — Firestore writes are asynchronous, so there was a race condition where both users could swipe at roughly the same time and the match wouldn't fire. I solved this by running the check both on swipe write *and* on the matches stream listener.


### Faris Bin Suhaimi – 2317561

**What I worked on:** The social network layer — friend connection system, friends list screen, search users screen and Firestore database for friends feature.

**Details:**

**1. Friend connection system.** I built the friend request and friendship logic in `lib/services/friend_service.dart`. Users can search for other users by username in `lib/screens/search_users_screen.dart`, and send a friend request that writes a document to the `friend_requests` Firestore collection. The recipient sees pending requests and can accept or decline. Once accepted, a `friendships` document is created, linking the two users. I managed the state transitions between "not connected," "pending," and "connected" so the UI always shows the correct button on each user's profile.

**2. Friends list and search users screen.** The friends list screen (`lib/screens/friends_screen.dart`) shows all connected friends with their profile photos and online status. When the user clean on the search bar and type the name, it will search through database all the existing users on (`lib/screens/search_users_screen.dart`) page. I built reusable card widgets (`lib/widgets/friend_card.dart` and `lib/widgets/friend_request_card.dart`) that are used across both screens for consistency.

**Problems faced:**

- *Duplication* — Whenever the user accept the friend request, it adds the widget card but duplicates from the existing one rather than the correct friend user.
- *Friend cannot be deleted after accept the friend request* - When the user accept the friend, it cannot delete because there is no button for it in the UI page and the user have to refresh.

### Abu Marwan Bin Abu Zakie – 2221579

**What I worked on:** The TMDB (The Movie Database) API integration, the movie data model, data parsing and caching, and the infinite scroll/pagination for the swipe deck.

**Details:**

**1. TMDB API service.** I built the TMDB API integration layer in `lib/services/tmdb_api/tmdb_service.dart`. This service handles all HTTP requests to TMDB's REST API — fetching popular movies, searching by genre, and retrieving movie details like posters, ratings, release dates, and overviews. I used Flutter's `http` package for the requests and parsed the JSON responses into Dart objects.

**2. Movie data model.** I created the `Movie` model class in `lib/services/tmdb_api/movie_model.dart` with all the fields the app needs: id, title, overview, poster path, backdrop path, release date, vote average, and genre IDs. The model includes a `fromJson()` factory constructor for clean JSON parsing and a `toJson()` method for serialising movie data into Firestore when needed.

**3. Pagination and infinite scroll.** The TMDB API returns results in pages, so I implemented pagination logic that fetches the next page of movies when the user is running low on cards. This keeps the swipe deck populated without loading hundreds of movies at once, which would be wasteful on both bandwidth and TMDB rate limits. I used TMDB's `page` query parameter and tracked the current page state in the service.

**4. Image handling.** Movie posters and backdrops need to be displayed at different sizes across the app (card thumbnails, match overlay, shared matches grid). I built helper methods that construct the correct TMDB image URL with the appropriate size parameter (`w185`, `w500`, `original`) so we don't download full-resolution images for small thumbnails.

**Problems faced:**

- *TMDB rate limits* — the free tier limits API calls, and during testing I occasionally hit the rate cap. I mitigated this by adding request debouncing and reusing cached movie data where possible instead of re-fetching.
- *Movie data not loading on slow connections* — some poster images would show as blank on slow networks. I added placeholder widgets and used Flutter's `FadeInImage` for smooth loading transitions.
- *JSON parsing errors* — TMDB sometimes returns null fields for movies missing certain metadata (e.g., no poster, no overview). I made all optional fields nullable in the model and added null checks in the UI to prevent crashes.

### Muhammad Alif Zakwan Bin Mohd Shukri – 2312225

**What I worked on:** Firebase project initialisation, the authentication flow (login, register, splash screen), and the user profile screen with avatar upload capability.

**Details:**

**1. Firebase setup and initialisation.** I set up the Firebase project from scratch, added the Android and iOS app registrations, and downloaded the configuration files. In `lib/main.dart`, I ensured Firebase initialises before the app UI is built by calling `WidgetsFlutterBinding.ensureInitialized()` followed by `Firebase.initializeApp()`. I wired in the `firebase_core`, `firebase_auth`, `cloud_firestore`, and `firebase_storage` packages in `pubspec.yaml`.

**2. Authentication screens.** The auth flow lives in three screens: `lib/screens/splash_screen.dart` (decides whether to show login or home based on auth state), `lib/screens/login_screen.dart`, and `lib/screens/signup_screen.dart`. I built the auth service (`lib/services/auth_service.dart`) that wraps Firebase Auth calls — `signUp()`, `signIn()`, and `logOut()` — so the screens don't call Firebase directly. I used Flutter's `Form` and `TextFormField` with validators to catch empty or invalid fields before they reach Firebase. Error handling maps Firebase error codes to user-friendly messages like "Invalid email or password" instead of raw codes.

**3. User profile screen.** The profile screen (`lib/screens/profile_screen.dart`) lets users set a display name, upload a profile avatar, and see their account details. I built the profile service (`lib/services/profile_service.dart`) that handles writing user data to the `users` Firestore collection on signup and updating it when the profile is edited. The avatar upload uses `image_picker` to select a photo from the gallery, then uploads it to Firebase Storage and stores the download URL in the user's Firestore document.

**4. Auth state handling and navigation.** I set up an auth state listener that streams the current Firebase user. When the user is null (logged out), the app shows the login/signup screens. When they log in, it navigates to the main app with the discover screen. The splash screen acts as the decision point — it shows the app logo while Firebase checks the auth state, then routes accordingly. The bottom navigation bar (`lib/widgets/app_bottom_nav_bar.dart`) handles switching between the main sections: Discover, Matches, Friends, and Profile.

**Problems faced:**

- *Firebase wouldn't initialise in time* — the app would crash on startup because it tried to access Firestore before Firebase was ready. I fixed this by awaiting `Firebase.initializeApp()` in `main()` before calling `runApp()`.
- *Auth state flickering* — the splash screen would briefly flash the login screen before navigating. I added a short delay and a loading indicator to make the transition seamless.
- *Image upload permissions* — on Android, the app needed runtime storage permissions to access the photo gallery. I added permission handling for Android 13+ using the `image_picker` package's built-in permission flow.

---

## How to Run

1. Clone the repository:
   ```
   git clone https://github.com/kimchi11y/AuraView.git
   ```
2. Run `flutter pub get` to install the packages.
3. Make sure the Firebase config files are in place (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
4. Run `flutter run`.

After that, register an account, choose a friend to connect with, and you can start swiping on movies together.

---

## References

> Add your own sources here in APA format.

Firebase. (2024). *Add Firebase to your Flutter app*. Google. https://firebase.google.com/docs/flutter/setup

Firebase. (2024). *Get started with Firebase Authentication on Flutter*. Google. https://firebase.google.com/docs/auth/flutter/start

Firebase. (2024). *Get data with Cloud Firestore*. Google. https://firebase.google.com/docs/firestore/query-data/get-data

Flutter. (2024). *Build a form with validation*. https://docs.flutter.dev/cookbook/forms/validation

Flutter. (2024). *Send data to a new screen*. https://docs.flutter.dev/cookbook/navigation/passing-data

TMDB. (2024). *The Movie Database API*. https://developer.themoviedb.org/reference/intro/getting-started

flutter_card_swiper | Flutter package. (2024). Dart Packages. https://pub.dev/packages/flutter_card_swiper

image_picker | Flutter package. (2024). Dart Packages. https://pub.dev/packages/image_picker

---

## Generative AI Disclosure

- **Hakim (2313945):** Used Opencode (Deepseek v4) assistance for drafting the initial swipe card animation logic and match overlay widget structure. All code was reviewed and adjusted for the project's specific needs. Also used Google Stitch AI for inspiration and ideas for design of UI.
- **Faris (2317561):** Used Claude Code assistance to help structure the Firestore compound queries for the shared matches feed and debug the friend request state management flow.\.
- **Abu (2221579):** Used Gemini Pro (3.1 Pro) assistance for generating the JSON parsing boilerplate for the TMDB movie model and structuring the pagination logic.
- **Alif (2312225):** Used ChatGPT AI to troubleshoot Firebase initialisation timing issues and generate the form validation boilerplate for login and signup screens.
