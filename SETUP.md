# BigSize Shop Setup Guide

This project is split into two roots:

- `Frontend/` for Flutter
- `backend/` for Node.js + Prisma

This guide sets up the project from zero and prepares it to work with Supabase.

## 1. Prerequisites

Install these tools first:

- Flutter SDK
- Node.js 20+ and npm
- Git
- A Supabase project
- VS Code or Android Studio / IntelliJ

Optional but recommended:

- Prisma CLI is already installed through `backend/package.json`
- Supabase CLI if you want to manage the database locally

## 2. Project Structure

- `Frontend/`: Flutter app
- `backend/`: Express API, Prisma schema, Supabase database connection
- Root `.gitignore`: ignores Flutter build output, Node modules, Prisma generated files, and local env files

## 3. Supabase Preparation

### 3.1 Create or open your Supabase project

In the Supabase dashboard, collect these values:

- Project URL
- Anon key or publishable key
- Service role key
- Database connection string for Prisma

### 3.2 Use the correct environment values

Put the backend values in `backend/.env`.

Example:

```env
NODE_ENV=development
PORT=4000
JWT_SECRET=replace-with-a-long-random-secret
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_DB_URL=postgresql://postgres.your-project-ref:your-password@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres
```

Important notes:

- `SUPABASE_DB_URL` is what Prisma uses in `backend/prisma/schema.prisma`
- Keep `backend/.env` out of Git
- If you already have a local `DATABASE_URL`, you can keep it only for legacy use, but Prisma in this project uses `SUPABASE_DB_URL`

## 4. Backend Setup

Go to the backend folder:

```bash
cd backend
```

Install dependencies:

```bash
npm install
```

Generate the Prisma client:

```bash
npm run prisma:generate
```

### 4.1 Prisma schema

The Prisma schema is located at:

- `backend/prisma/schema.prisma`

It is already mapped to the existing Supabase tables:

- `users`
- `categories`
- `products`
- `cart_items`
- `orders`
- `order_items`
- `messages`
- `notifications`

### 4.2 When Supabase tables already exist

If the tables are already created in Supabase, you usually only need to:

1. Set `SUPABASE_DB_URL`
2. Run `npm run prisma:generate`
3. Implement repositories using Prisma Client

If the live Supabase database changes and you want Prisma to reflect it automatically, you can introspect again:

```bash
npx prisma db pull --schema prisma/schema.prisma
npm run prisma:generate
```

Use `db pull` carefully if you have custom schema edits you want to preserve.

### 4.3 Start the backend

Run the API server:

```bash
npm run dev
```

The API starts on the port defined in `backend/.env`.

## 5. Frontend Setup

Go to the Flutter project:

```bash
cd Frontend
```

Install Flutter packages:

```bash
flutter pub get
```

### 5.1 Supabase config for Flutter

The Flutter app reads Supabase values at compile time from `dart-define`.

Required values:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The app also supports fallback to:

- `SUPABASE_ANON_KEY`

Example run command:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

If you only have the anon key, this also works:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### 5.2 Start the Flutter app

```bash
flutter run
```

If you want to run on a specific platform, use the normal Flutter target commands.

## 6. Development Flow

Recommended order:

1. Set up Supabase project and copy the keys
2. Fill `backend/.env`
3. Run `npm install` in `backend/`
4. Run `npm run prisma:generate` in `backend/`
5. Run `flutter pub get` in `Frontend/`
6. Start backend with `npm run dev`
7. Start frontend with `flutter run`

## 7. Working With Prisma and Supabase

### 7.1 Backend repositories

The Prisma client is wired through:

- `backend/src/common/config/prisma.js`

Repositories should import that singleton and query the database through it.

### 7.2 Typical Prisma commands

From `backend/`:

```bash
npm run prisma:generate
npx prisma db pull --schema prisma/schema.prisma
npx prisma validate --schema prisma/schema.prisma
```

### 7.3 When to use db pull

Use `db pull` if:

- you added or changed tables directly in Supabase
- you want Prisma models synced from the live database

Do not use it blindly if you already made custom Prisma-only changes that are not in Supabase yet.

## 8. Git Ignore Notes

The root `.gitignore` already ignores:

- Flutter build and cache folders
- Node `node_modules`
- backend `.env`
- Prisma generated files and migration SQL

If Git was already tracking `backend/.env`, remove it from the index once:

```bash
git rm --cached backend/.env
```

## 9. Quick Validation

After setup, these checks should pass:

```bash
cd backend
npm run prisma:generate

cd ../Frontend
flutter analyze
```

If both pass, the project is ready for feature development against Supabase.
