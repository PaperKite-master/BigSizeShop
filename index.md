# BigSize Shop — Connection Setup Guide

This guide covers how **Backend (Prisma → Supabase Postgres)** and **Frontend (Flutter → Express API)** connect in your project.

---

## Architecture overview

```mermaid
flowchart LR
    subgraph Flutter
        UI[Screens]
        Services[Auth / Product / Category Services]
        Dio[ApiClient - Dio]
        Storage[Secure Storage - JWT]
    end

    subgraph Backend
        Express[Express API]
        Prisma[Prisma Client]
    end

    subgraph Supabase
        PG[(PostgreSQL)]
    end

    UI --> Services --> Dio
    Dio -->|HTTP REST| Express
    Storage -->|Bearer token| Dio
    Express --> Prisma --> PG
```
![](diagram.drawio.png)
**Important:** Your app does **not** use Supabase Auth or Supabase REST for business APIs.  
- **Backend** talks to Supabase **only as a PostgreSQL database** via Prisma.  
- **Flutter** talks to your **Express backend** via Dio HTTP.

`supabase_flutter` in `main.dart` is initialized for future features, but auth/products/categories go through your Node API.

---

## Part 1: Prisma + Supabase (Backend)

### Step 1 — Create Supabase project

1. Go to [supabase.com](https://supabase.com) → create a project.
2. Wait for the database to be ready.
3. Open **Project Settings → Database**.

You need **two** connection strings:

| Purpose | Port | Used by |
|---------|------|---------|
| **Connection pooling** (Transaction mode) | `6543` | Runtime app (`SUPABASE_DB_URL`) |
| **Direct connection** | `5432` | Prisma CLI (`DIRECT_URL`) — migrations, `db pull` |

### Step 2 — Configure backend `.env`

Copy `backend/.env.example` to `backend/.env`:

```env
NODE_ENV=development
PORT=4000
JWT_SECRET="your-long-random-secret"

SUPABASE_URL="https://your-project-ref.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# Pooled connection (port 6543) — used at runtime
SUPABASE_DB_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres?pgbouncer=true"

# Direct connection (port 5432) — used by Prisma CLI
DIRECT_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres"
```

Get these from Supabase → **Connect** → **ORM** (Prisma) or **Connection string**.

### Step 3 — Prisma schema

`backend/prisma/schema.prisma` defines the datasource:

```5:9:backend/prisma/schema.prisma
datasource db {
  provider  = "postgresql"
  url       = env("SUPABASE_DB_URL")
  directUrl = env("DIRECT_URL")
}
```

- `url` → pooled URL for the running server  
- `directUrl` → direct URL for Prisma CLI operations  

Models (e.g. `User`, `Product`) map to Supabase tables via `@@map("users")`, etc.

### Step 4 — Sync schema and generate client

From `backend/`:

```bash
npm install

# If tables already exist in Supabase, pull schema into Prisma:
npx prisma db pull --schema prisma/schema.prisma

# Generate the Prisma client (required after schema changes):
npm run prisma:generate
```

`package.json` script:

```8:8:backend/package.json
    "prisma:generate": "prisma generate --schema prisma/schema.prisma",
```

### Step 5 — Prisma client singleton (important Supabase fix)

`backend/src/common/config/prisma.js` creates one shared client and fixes the **PgBouncer prepared statement** issue:

```1:38:backend/src/common/config/prisma.js
const { PrismaClient } = require('@prisma/client');

function getDatabaseUrl() {
  const url = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
  // ...
  const usesPooler = url.includes('pooler.supabase.com') || url.includes(':6543');

  if (usesPooler) {
    const separator = url.includes('?') ? '&' : '?';
    return `${url}${separator}pgbouncer=true`;
  }
  return url;
}

const prisma =
  globalThis.prisma ||
  new PrismaClient({
    datasources: {
      db: { url: getDatabaseUrl() },
    },
  });
```

**Why this matters:** Supabase pooler (port 6543) uses PgBouncer. Without `pgbouncer=true`, Prisma can throw errors like `prepared statement does not exist`.

**Singleton pattern:** In development, the client is cached on `globalThis.prisma` to avoid too many connections during hot reload.

### Step 6 — How repositories use Prisma

Repositories import the singleton and run queries. Example from auth:

```1:32:backend/src/modules/auth/repositories/auth.repository.js
const { prisma } = require('../../../common/config/prisma');

async function findUserByEmail(email) {
  return prisma.user.findUnique({
    where: { email },
  });
}

async function createUser(userData) {
  return prisma.user.create({
    data: userData,
    select: USER_PUBLIC_SELECT,
  });
}
```

**Prisma methods used in this project:**

| Method | Purpose | Example |
|--------|---------|---------|
| `findUnique` | Get one row by unique field | Login by email |
| `findMany` | List with filters/pagination | Product listing |
| `count` | Total for pagination | Product meta |
| `create` | Insert | Register user, create product |
| `update` | Update by id | Edit category |
| `delete` | Remove by id | Delete product |

Layer flow: **Route → Controller → Service → Repository → Prisma → Supabase Postgres**

### Step 7 — Start backend

```bash
cd backend
npm run dev
```

Server starts on port `4000` and validates env (`JWT_SECRET`, DB URL) in `server.js`.

**API docs:** http://localhost:4000/api-docs

---

## Part 2: Flutter → Backend API

### Step 1 — Set API base URL

`Frontend/lib/core/constants/app_constants.dart`:

```1:12:Frontend/lib/core/constants/app_constants.dart
class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  static const String tokenKey = 'auth_token';
}
```

**Run commands by platform:**

```bash
cd Frontend
flutter pub get

# Web / Windows
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000

# Android emulator (localhost = 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000

# Physical device (use your PC's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:4000
```

### Step 2 — HTTP client (Dio)

`Frontend/lib/core/network/api_client.dart` is the core HTTP layer.

**What it does:**
1. Sets `baseUrl` to your backend  
2. Adds `Content-Type: application/json`  
3. **Interceptor** reads JWT from secure storage and adds `Authorization: Bearer <token>`  
4. Wraps errors into `ApiException` using backend `{ message: "..." }`

```7:31:Frontend/lib/core/network/api_client.dart
class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
```

**HTTP methods exposed:**

| Method | Dio call | Used for |
|--------|----------|----------|
| `get()` | `_dio.get()` | List products, categories, `/auth/me` |
| `post()` | `_dio.post()` | Register, login, logout, create |
| `put()` | `_dio.put()` | Update category/product |
| `delete()` | `_dio.delete()` | Delete category/product |

### Step 3 — JWT storage

`Frontend/lib/core/storage/secure_storage_service.dart` uses `flutter_secure_storage`:

- `saveToken()` — after login  
- `readToken()` — before each request (via interceptor)  
- `deleteToken()` — on logout  

### Step 4 — Service layer (API calls)

Each feature has a service that calls `ApiClient`. Example — auth:

```9:55:Frontend/lib/services/auth_service.dart
Future<UserModel> register({...}) async {
  final response = await _client.post<Map<String, dynamic>>(
    '/auth/register',
    data: { 'fullName': fullName, 'email': email, 'password': password },
  );
  return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
}

Future<AuthSession> login({...}) async {
  final response = await _client.post<Map<String, dynamic>>(
    '/auth/login',
    data: { 'email': email, 'password': password },
  );
  // Returns { token, user }
}

Future<UserModel> me() async {
  final response = await _client.get<Map<String, dynamic>>('/auth/me');
  return UserModel.fromJson(response.data!['data'] as Map<String, dynamic>);
}
```

Products with query params:

```56:102:Frontend/lib/services/product_service.dart
Future<ProductListResult> list(ProductQuery query) async {
  return _fetchProducts('/products', query);
}

Future<ProductListResult> _fetchProducts(String path, ProductQuery query) async {
  final response = await _client.get<Map<String, dynamic>>(
    path,
    queryParameters: query.toQueryParameters(),
  );
  // Parses response.data['data'] and response.data['meta']
}
```

**Backend response shape** (consistent across endpoints):

```json
{
  "message": "Products fetched",
  "data": [ ... ]  or { ... },
  "meta": { "total": 10, "page": 1, "limit": 12, "totalPages": 1 }
}
```

### Step 5 — State management (Riverpod)

`Frontend/lib/providers/app_providers.dart` wires dependencies:

```
SecureStorage → ApiClient → AuthService / ProductService / CategoryService
```

**Auth flow:**

```46:98:Frontend/lib/providers/app_providers.dart
// On app start: read token → call GET /auth/me
Future<void> _restoreSession() async { ... }

// Login: POST /auth/login → save token → update state
Future<void> login(...) async {
  final session = await _authService.login(...);
  await _storage.saveToken(session.token);
  return session.user;
}

// Logout: POST /auth/logout → delete token
Future<void> logout() async { ... }
```

UI screens use `ref.watch(authControllerProvider)` and call `ref.read(authControllerProvider.notifier).login(...)`.

### Step 6 — Protected routes on backend

Backend checks JWT in middleware:

```4:14:backend/src/common/middleware/auth.middleware.js
function authenticate(req, res, next) {
  const token = authHeader.slice(7);
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  req.user = decoded;  // { id, email, role }
  next();
}
```

Flutter sends the token automatically via the Dio interceptor — no manual header in screens.

Admin routes also use `requireAdmin` (`role === 'ADMIN'`).

---

## Part 3: End-to-end API map

| Feature | Flutter service | HTTP | Backend route | Prisma |
|---------|-----------------|------|---------------|--------|
| Register | `AuthService.register` | POST | `/auth/register` | `prisma.user.create` |
| Login | `AuthService.login` | POST | `/auth/login` | `prisma.user.findUnique` |
| Profile | `AuthService.me` | GET | `/auth/me` | `prisma.user.findUnique` |
| Logout | `AuthService.logout` | POST | `/auth/logout` | — |
| List categories | `CategoryService.list` | GET | `/categories` | `prisma.category.findMany` |
| List products | `ProductService.list` | GET | `/products?page=1&limit=12` | `prisma.product.findMany` |
| Search | `ProductService.search` | GET | `/products/search?search=nike` | `findMany` + `contains` |
| Filter | `ProductService.filter` | GET | `/products/filter?category=shirt` | `findMany` + filters |
| Product detail | `ProductService.getById` | GET | `/products/:id` | `prisma.product.findUnique` |

---

## Part 4: Quick start checklist

### Backend
- [ ] Create Supabase project  
- [ ] Copy connection strings to `backend/.env`  
- [ ] Run `npm install`  
- [ ] Run `npm run prisma:generate`  
- [ ] Run `npm run dev`  
- [ ] Open http://localhost:4000/api-docs  

### Frontend
- [ ] Run `flutter pub get`  
- [ ] Start backend first  
- [ ] Run Flutter with correct `API_BASE_URL` for your device  
- [ ] Register → Login → Browse products  
- [ ] For admin: set `role = 'ADMIN'` in Supabase, login again  

---

## Common issues

| Problem | Cause | Fix |
|---------|-------|-----|
| `Cannot reach API at ...` | Wrong `API_BASE_URL` or backend not running | Start backend; use `10.0.2.2` on Android emulator |
| `prepared statement does not exist` | Supabase pooler without `pgbouncer=true` | Ensure `prisma.js` fix + `?pgbouncer=true` in URL |
| `Unauthorized` on admin routes | User is not ADMIN or token missing | Promote user in Supabase; login again |
| CORS errors | Backend not allowing origin | Your backend already has `cors()` enabled |

---

## Summary

- **Supabase** = PostgreSQL host. **Prisma** = ORM that queries it.  
- **Express** = REST API your Flutter app calls.  
- **Dio** = HTTP client; **Riverpod** = state; **Secure Storage** = JWT persistence.  
- Connection is: **Flutter UI → Service → ApiClient (Dio) → Express → Prisma → Supabase Postgres**.



