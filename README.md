# SongSurf

SongSurf is a music discovery app that lets you share and receive song recommendations with random users worldwide. Send a song into the universe and catch a wave of musical inspiration in return!

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Supabase account
- Spotify Developer account
- Android Studio / Xcode (for mobile deployment)

## Setup Instructions

1. **Install Flutter**
   ```bash
   # macOS
   brew install flutter
   
   # Verify installation
   flutter doctor
   ```

2. **Create Supabase Project**
   - Visit [Supabase](https://supabase.com)
   - Create a new project
   - Save your project URL and anon key

3. **Setup Spotify Developer Account**
   - Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Create a new application
   - Save your Client ID and Client Secret

4. **Environment Setup**
   - Copy `.env.example` to `.env`
   - Fill in your Supabase and Spotify credentials

5. **Install Dependencies**
   ```bash
   flutter pub get
   ```

6. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models
├── services/        # API services
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── utils/          # Helper functions
└── main.dart       # Entry point
```

## Database Schema

### Users Table
- id (uuid, primary key)
- email (text)
- created_at (timestamp)
- last_recommendation_time (timestamp)

### Recommendations Table
- id (uuid, primary key)
- sender_id (uuid, foreign key)
- receiver_id (uuid, foreign key)
- song_id (text)
- song_name (text)
- artist_name (text)
- created_at (timestamp)
- status (text) - ['pending', 'matched']

## Features

- Spotify integration for song selection
- Random song recommendation matching
- 24-hour cooldown system
- User authentication
- Real-time updates

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
