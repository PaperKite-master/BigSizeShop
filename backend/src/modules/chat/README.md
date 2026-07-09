# chat module

REST API for chat messages + Supabase Realtime on the Flutter client.

## API (Vế Gửi)

All routes require `Authorization: Bearer <JWT>`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/chats` | List chats for current user |
| POST | `/chats` | Customer opens support chat |
| GET | `/chats/:chatId/messages` | Message history |
| POST | `/chats/:chatId/messages` | Send message → inserts into `messages` table |

Send message body:

```json
{ "content": "Xin chào shop!" }
```

## Realtime (Vế Nhận)

1. Enable **Replication** for table `messages` in Supabase Dashboard → Database → Replication.
2. Run Flutter with Supabase env:

```bash
flutter run -d windows \
  --dart-define=API_BASE_URL=http://localhost:4000 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

3. `SupabaseRealtimeService.subscribeToChatMessages` listens for `INSERT` on `messages` filtered by `chat_id`.

Flow: **Flutter POST → Express → Prisma → Postgres → Supabase Realtime → Flutter UI**
