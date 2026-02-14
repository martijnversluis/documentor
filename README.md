# Documentor

A personal productivity app built with Ruby on Rails, combining GTD (Getting Things Done) methodology with document management.

## Features

- **Action Items**: Task management with due dates, contexts, and sub-items
- **Dossiers & Folders**: Organize documents and notes by topic
- **Reviews**: GTD-style weekly reviews with customizable templates
- **Habits**: Daily habit tracking with streaks
- **Integrations**:
  - Google Calendar: View upcoming meetings and events
  - Gmail: See unread emails and create action items
  - GitHub: Track issues and pull requests assigned to you
  - Waste Calendar: Reminders to put out the bins (Dutch waste collection via Ximmio API)

## Requirements

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 20+

## Setup

### 1. Clone and install dependencies

```bash
git clone https://github.com/your-username/documentor.git
cd documentor
bundle install
npm install
```

### 2. Configure encryption keys

Create a `.env` file with Active Record Encryption keys:

```bash
# Generate keys
bin/rails db:encryption:init
```

Add the generated keys to `.env`:

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...
```

### 3. Setup database

```bash
bin/rails db:create db:migrate db:seed
```

### 4. Start the development server

```bash
bin/dev
```

The app will be available at `http://localhost:3001`

### 5. Configure integrations (optional)

Go to `/settings/configuration` to set up OAuth credentials for:

#### Google (Calendar & Gmail)

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new OAuth 2.0 Client ID
3. Add authorized redirect URI: `http://localhost:3001/settings/google_accounts/callback`
4. Enable Google Calendar API and Gmail API
5. Enter the Client ID and Secret in the app settings

#### GitHub

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App
3. Set callback URL: `http://localhost:3001/settings/github_accounts/callback`
4. Enter the Client ID and Secret in the app settings

## Running Tests

```bash
bin/rspec
```

## Background Jobs

Documentor uses SolidQueue for background jobs. Jobs are configured in `config/recurring.yml`:

- **Waste Calendar Sync**: Daily at 5am
- **Waste Calendar Check**: Daily at 6pm (creates action items for next day's pickup)
- **Charging Check**: Every 2 hours
- **Expiration Check**: Daily at 8am

## Deployment

The app includes a `config/deploy.yml` for deployment with Kamal. Update the configuration with your server details.

For production, set these environment variables:
- `SECRET_KEY_BASE`
- `DOCUMENTOR_DATABASE_PASSWORD`
- `ACTIVE_RECORD_ENCRYPTION_*` keys

## License

MIT License - see [LICENSE](LICENSE) for details.
