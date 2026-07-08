---
title: "Api Protocols Deepdive"
tags:
  - library
  - platform-technologies
aliases:
  - "api-protocols-deepdive"
created: "2026-05-29"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

# 🔌 API PROTOCOLS — Deep Dive: REST, gRPC, WebSocket, GraphQL

> **Pesan terpenting:** Tidak ada protokol yang "terbaik". Yang ada adalah protokol yang **paling sesuai dengan use case**. Memilih gRPC hanya karena "5ms lebih cepat dari REST" tanpa memahami konteksnya = keputusan arsitektur yang salah.

> [!warning] Koreksi Angka TikTok
> Perbandingan di viral tersebut **bukan apple-to-apple**:
>
> - REST uncached 150ms vs GraphQL 15ms: GraphQL **lebih lambat** dari REST tanpa DataLoader karena N+1 problem
> - WebSocket 50ms: itu **connection setup overhead**, bukan per-message latency. Setelah connected, pesan bisa < 1ms
> - gRPC 5ms: valid hanya untuk **internal service** dengan persistent connection dan protobuf. Tidak cocok untuk browser langsung

---

## Daftar Isi

- [[#Arsitektur Setiap Protokol]]
- [[#REST — Fondasi yang Sering Disalahpahami]]
- [[#gRPC — Kecepatan Internal Service]]
- [[#WebSocket — Real-Time Bidirectional]]
- [[#GraphQL — Fleksibilitas Query]]
- [[#Decision Matrix — Kapan Pakai Yang Mana]]
- [[#Best Practices per Protokol]]
- [[#Kombinasi Pattern — Dunia Nyata]]

---

## Arsitektur Setiap Protokol

```
LAYER STACK per Protokol:

REST:
Client → HTTP/1.1 atau HTTP/2 → JSON payload → Server
[Stateless, request-response, human readable]

gRPC:
Client → HTTP/2 (multiplexed) → Protobuf binary → Server
[Bidirectional streaming, binary, strongly typed schema]

WebSocket:
Client → HTTP upgrade handshake → WS persistent connection → Server
[Stateful, bidirectional, low latency after connection]

GraphQL:
Client → HTTP/1.1 atau HTTP/2 → JSON query → GraphQL runtime → Resolver → DB
[Single endpoint, client-defined response shape, N+1 risk]

POSISI DI STACK:
┌─────────────────────────────────────────────────────┐
│                 APPLICATION LAYER                   │
│  REST     GraphQL    gRPC       WebSocket           │
├─────────────────────────────────────────────────────┤
│                 TRANSPORT LAYER                     │
│  HTTP/1.1  HTTP/1.1  HTTP/2     HTTP → WS upgrade  │
├─────────────────────────────────────────────────────┤
│                  NETWORK LAYER                      │
│                     TCP                             │
└─────────────────────────────────────────────────────┘
```

---

## REST — Fondasi yang Sering Disalahpahami

### Apa yang Sebenarnya REST Itu

```
REST = Representational State Transfer
Bukan protokol — ini ARCHITECTURAL STYLE dengan 6 constraints:

1. Client-Server separation
2. Stateless (setiap request berdiri sendiri, server tidak simpan state client)
3. Cacheable (response bisa di-cache)
4. Uniform Interface (HTTP verbs: GET/POST/PUT/PATCH/DELETE)
5. Layered System (boleh ada proxy/cache di antara client-server)
6. Code on Demand (opsional: server bisa kirim executable code)

Yang sering dikira REST tapi bukan:
❌ "REST hanya JSON" — XML, YAML, plain text semua valid
❌ "REST = CRUD biasa" — REST bisa kompleks
❌ "REST pasti lambat" — dengan caching yang benar, REST bisa sangat cepat

REST yang BENAR vs REST yang Buruk:
BURUK:  POST /getUser       (verb di URL, pakai POST untuk read)
        POST /deleteUser    (aksi di URL)
        GET  /users?action=delete  (berbahaya!)

BENAR:  GET    /users/{id}        (read)
        POST   /users             (create)
        PUT    /users/{id}        (replace full)
        PATCH  /users/{id}        (update partial)
        DELETE /users/{id}        (delete)
```

### Caching — Kenapa REST Bisa 25ms

```
HTTP CACHING HIERARCHY:

Request → [Browser Cache] → [CDN Cache] → [Reverse Proxy] → [App Cache] → DB
             ↑                   ↑               ↑               ↑
           Cache-Control      Edge cache      Nginx/Varnish   Redis/Memcached

Cache-Control Headers (kunci):
┌─────────────────────────────────────────────────────────────┐
│ Cache-Control: public, max-age=300                          │
│ → Siapapun (CDN, browser) boleh cache selama 5 menit        │
│                                                             │
│ Cache-Control: private, max-age=60                         │
│ → Hanya browser yang boleh cache (sensitif per user)       │
│                                                             │
│ Cache-Control: no-cache                                     │
│ → Selalu cek ke server, tapi boleh pakai cache jika valid  │
│                                                             │
│ Cache-Control: no-store                                     │
│ → JANGAN cache sama sekali (sensitif: banking, health)     │
│                                                             │
│ ETag: "abc123"                                              │
│ → Fingerprint response. Client kirim If-None-Match         │
│ → Server return 304 Not Modified jika tidak berubah        │
└─────────────────────────────────────────────────────────────┘

KENAPA gRPC tidak bisa seredah 25ms dengan caching:
→ Protobuf bukan human-readable → CDN tidak bisa cache dengan mudah
→ HTTP/2 streaming = tidak cocok untuk standard CDN caching
→ REST + CDN caching = lebih scalable untuk public API
```

### REST Best Practices

```python
# FastAPI — contoh REST yang proper

from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import httpx

app = FastAPI()

# ─── RESPONSE YANG KONSISTEN ──────────────────────────────────
# Selalu gunakan response schema yang sama
class APIResponse(BaseModel):
    success: bool
    data: dict | list | None = None
    error: str | None = None
    pagination: dict | None = None

# ─── HTTP STATUS CODE YANG BENAR ──────────────────────────────
# Ini yang sering salah: semua return 200 padahal ada error
@app.get("/users/{user_id}")
async def get_user(user_id: int):
    user = await db.get_user(user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,  # ← bukan 200!
            detail="User not found"
        )

    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={"success": True, "data": user.dict()}
    )

@app.post("/users", status_code=status.HTTP_201_CREATED)  # ← 201 untuk create
async def create_user(user: UserCreate):
    ...

# ─── VERSIONING ───────────────────────────────────────────────
# Selalu version API untuk backward compatibility
# /api/v1/users  → versi lama (tetap jalan)
# /api/v2/users  → versi baru dengan breaking changes

# ─── PAGINATION YANG PROPER ───────────────────────────────────
@app.get("/users")
async def list_users(
    page: int = 1,
    limit: int = 20,           # ← default limit, jangan no limit!
    cursor: str | None = None  # cursor-based untuk large dataset
):
    # Cursor-based pagination lebih efisien untuk large table
    # dibanding offset-based (LIMIT x OFFSET y semakin lambat semakin besar offset)
    ...
    return {
        "data": users,
        "pagination": {
            "next_cursor": "abc123",
            "has_more": True,
            "total": 10000
        }
    }

# ─── IDEMPOTENCY KEY ──────────────────────────────────────────
# Untuk POST yang tidak boleh duplicate (payment, order)
@app.post("/payments")
async def create_payment(
    payment: PaymentCreate,
    idempotency_key: str = Header(...)  # Client generate UUID, kirim di header
):
    # Cek apakah key ini sudah pernah diproses
    existing = await cache.get(f"payment:{idempotency_key}")
    if existing:
        return existing  # Return hasil sebelumnya, bukan proses ulang

    result = await process_payment(payment)
    await cache.set(f"payment:{idempotency_key}", result, ttl=86400)
    return result
```

---

## gRPC — Kecepatan Internal Service

### Mengapa 5ms — Mekanisme di Baliknya

```
KENAPA gRPC LEBIH CEPAT DARI REST (dalam kondisi yang tepat):

1. PROTOCOL BUFFERS (Protobuf) vs JSON:

JSON:
{"user_id": 12345, "username": "azhar", "email": "azhar@example.com"}
→ 64 bytes, human readable, perlu parsing string

Protobuf:
\x08\xb9\x60\x12\x05azhar\x1a\x13azhar@example.com
→ ~25 bytes (60% lebih kecil), binary, no parsing overhead

BENCHMARK SERIALIZATION:
JSON serialize:   ~1.5μs per operation
Protobuf serialize: ~0.3μs per operation (5x lebih cepat)

2. HTTP/2 MULTIPLEXING:

HTTP/1.1: satu request per connection (kecuali pakai keep-alive)
          Request 1 ──────────────► Response 1
          Request 2 ──────────────► Response 2 (menunggu Response 1)

HTTP/2 gRPC: multiple stream dalam satu connection
          Stream 1: Request ──────────────► Response 1
          Stream 2: Request ──────────────► Response 2
          Stream 3: Request ──────────────► Response 3
          (semua parallel, tidak blocking)

3. PERSISTENT CONNECTION:
REST: setiap request bisa buka connection baru (TCP handshake overhead)
gRPC: connection tetap terbuka, reuse untuk banyak call
→ TCP handshake dihilangkan setelah koneksi pertama

4. STRONGLY TYPED CONTRACT (.proto file):
→ Compiler yang cek type mismatch, bukan runtime error
→ Auto-generate client code untuk berbagai bahasa
```

### .proto File — Schema First

```protobuf
// user.proto
syntax = "proto3";

package user;

// Definisi message = tipe data
message User {
  int32 id = 1;
  string username = 2;
  string email = 3;
  repeated string roles = 4;  // array of string
  optional string bio = 5;    // nullable field
}

message GetUserRequest {
  int32 id = 1;
}

message ListUsersRequest {
  int32 page = 1;
  int32 limit = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
  bool has_more = 3;
}

// Definisi service = endpoint
service UserService {
  // Unary: satu request, satu response (seperti REST)
  rpc GetUser(GetUserRequest) returns (User);

  // Server streaming: satu request, BANYAK response
  rpc ListUsers(ListUsersRequest) returns (stream User);

  // Client streaming: BANYAK request, satu response
  rpc BatchCreateUsers(stream User) returns (BatchResult);

  // Bidirectional streaming: banyak request + banyak response
  rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}
```

```python
# Server implementation (Python)
import grpc
from concurrent import futures
import user_pb2
import user_pb2_grpc

class UserServicer(user_pb2_grpc.UserServiceServicer):

    # Unary RPC
    def GetUser(self, request, context):
        user = db.get_user(request.id)
        if not user:
            context.set_code(grpc.StatusCode.NOT_FOUND)
            context.set_details("User not found")
            return user_pb2.User()

        return user_pb2.User(
            id=user.id,
            username=user.username,
            email=user.email
        )

    # Server streaming RPC
    def ListUsers(self, request, context):
        # Yield satu per satu — client terima stream
        for user in db.list_users(page=request.page, limit=request.limit):
            yield user_pb2.User(
                id=user.id,
                username=user.username
            )
            # Jika client cancel (disconnect), context.is_active() = False
            if not context.is_active():
                break

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    user_pb2_grpc.add_UserServiceServicer_to_server(UserServicer(), server)
    server.add_insecure_port('[::]:50051')
    server.start()
    server.wait_for_termination()
```

### Kapan gRPC Tidak Cocok

```
JANGAN pakai gRPC untuk:
❌ Public API yang diakses browser langsung
   → Browser tidak support HTTP/2 trailer (dibutuhkan gRPC)
   → Solusi: gRPC-Web (tapi butuh proxy seperti Envoy)
   → Lebih baik: REST atau GraphQL untuk browser

❌ Human debugging tanpa tools
   → Protobuf binary = tidak bisa curl dan lihat response
   → Butuh: grpcurl, Postman gRPC, atau decode manual

❌ Simple CRUD dengan sedikit client
   → Overhead setup .proto + code generation tidak worth it
   → REST + JSON jauh lebih simple

COCOK untuk:
✅ Internal microservice ke microservice
✅ High-throughput data pipeline
✅ Mobile app (bandwidth efficiency)
✅ Polyglot environment (auto-generate client untuk 10+ bahasa)
✅ Real-time bidirectional streaming (bukan chat — untuk data stream)
```

---

## WebSocket — Real-Time Bidirectional

### Connection Lifecycle yang Perlu Dipahami

```
WEBSOCKET CONNECTION FLOW:

Fase 1: HTTP Upgrade Handshake (hanya sekali, ~50ms overhead)
Client:
  GET /ws HTTP/1.1
  Host: server.com
  Upgrade: websocket
  Connection: Upgrade
  Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
  Sec-WebSocket-Version: 13

Server:
  HTTP/1.1 101 Switching Protocols
  Upgrade: websocket
  Connection: Upgrade
  Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=

Fase 2: Persistent Connection (setelah ini latency per pesan ~1-5ms)
Client ──── message ────► Server
Server ──── message ────► Client
Client ──── message ────► Server
(bidirectional, kapanpun, tanpa perlu request-response pattern)

Fase 3: Close Handshake
Client ──── CLOSE frame ────► Server
Server ──── CLOSE frame ────► Client

OVERHEAD YANG SERING SALAH KAPRAH:
"WebSocket 50ms" di TikTok = biaya FASE 1 saja
Setelah handshake: setiap pesan hanya 2-byte header overhead
vs REST: HTTP header 500-800 bytes per request
```

### Implementasi WebSocket yang Proper

```python
# FastAPI WebSocket — dengan proper error handling dan rooms

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import Dict, List
import json
import asyncio

app = FastAPI()

class ConnectionManager:
    """Manage multiple WebSocket connections dengan rooms"""

    def __init__(self):
        # room_id → list of WebSocket connections
        self.rooms: Dict[str, List[WebSocket]] = {}
        # websocket → metadata (user_id, room_id)
        self.metadata: Dict[WebSocket, dict] = {}

    async def connect(self, websocket: WebSocket, room_id: str, user_id: str):
        await websocket.accept()

        if room_id not in self.rooms:
            self.rooms[room_id] = []

        self.rooms[room_id].append(websocket)
        self.metadata[websocket] = {"user_id": user_id, "room_id": room_id}

        # Notify others in room
        await self.broadcast_to_room(
            room_id,
            {"type": "user_joined", "user_id": user_id},
            exclude=websocket
        )

    def disconnect(self, websocket: WebSocket):
        meta = self.metadata.get(websocket, {})
        room_id = meta.get("room_id")

        if room_id and room_id in self.rooms:
            self.rooms[room_id].remove(websocket)
            if not self.rooms[room_id]:
                del self.rooms[room_id]

        del self.metadata[websocket]
        return meta

    async def broadcast_to_room(self, room_id: str, message: dict, exclude=None):
        if room_id not in self.rooms:
            return

        # Kirim ke semua connection dalam room, kecuali yang di-exclude
        dead_connections = []
        for websocket in self.rooms[room_id]:
            if websocket == exclude:
                continue
            try:
                await websocket.send_json(message)
            except Exception:
                dead_connections.append(websocket)

        # Cleanup dead connections
        for dead in dead_connections:
            self.disconnect(dead)

manager = ConnectionManager()

@app.websocket("/ws/{room_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    room_id: str,
    token: str  # Auth via query param untuk WS
):
    # Validate token sebelum accept
    user = await validate_token(token)
    if not user:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await manager.connect(websocket, room_id, user.id)

    try:
        while True:
            # Terima pesan dari client
            data = await websocket.receive_json()

            # Validate message schema
            if "type" not in data or "content" not in data:
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid message format"
                })
                continue

            # Handle berbagai tipe message
            if data["type"] == "chat":
                await manager.broadcast_to_room(
                    room_id,
                    {
                        "type": "chat",
                        "user_id": user.id,
                        "content": data["content"],
                        "timestamp": datetime.utcnow().isoformat()
                    }
                )

            elif data["type"] == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        meta = manager.disconnect(websocket)
        await manager.broadcast_to_room(
            meta.get("room_id", ""),
            {"type": "user_left", "user_id": user.id}
        )
```

### Masalah WebSocket yang Sering Diabaikan

```
PROBLEM 1: Scalability dengan Multiple Server Instance

Jika punya 3 server:
Server A ──── user1 (ws connected)
Server B ──── user2 (ws connected)
Server C ──── user3 (ws connected)

user1 kirim pesan ke user2:
→ Server A tidak tahu user2 ada di Server B!
→ Pesan tidak terdeliver

SOLUSI: Pub/Sub dengan Redis
Server A publish event ke Redis channel
Server B subscribe ke channel yang sama
→ Broadcast ke semua server

import redis.asyncio as aioredis

redis = await aioredis.from_url("redis://localhost")

# Publish (sender server)
await redis.publish("chat:room123", json.dumps(message))

# Subscribe (semua server)
pubsub = redis.pubsub()
await pubsub.subscribe("chat:room123")
async for message in pubsub.listen():
    # Forward ke local WebSocket connections
    await local_broadcast(message)

PROBLEM 2: Reconnection Logic (wajib di client)

Client JavaScript yang proper:
class ReconnectingWebSocket {
  constructor(url) {
    this.url = url;
    this.reconnectDelay = 1000;
    this.maxDelay = 30000;
    this.connect();
  }

  connect() {
    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      this.reconnectDelay = 1000; // reset delay
      console.log("Connected");
    };

    this.ws.onclose = (event) => {
      if (event.code !== 1000) { // 1000 = normal close
        setTimeout(() => this.connect(), this.reconnectDelay);
        this.reconnectDelay = Math.min(
          this.reconnectDelay * 2,
          this.maxDelay
        ); // exponential backoff
      }
    };

    // Heartbeat untuk detect dead connection
    setInterval(() => {
      if (this.ws.readyState === WebSocket.OPEN) {
        this.ws.send(JSON.stringify({type: "ping"}));
      }
    }, 30000);
  }
}

PROBLEM 3: Memory Leak dari Stale Connections
→ Mobile browser background = connection "zombie" (tidak close, tidak active)
→ Server menyimpan connection object yang tidak bisa dihubungi
→ Solusi: Heartbeat + server-side timeout
```

---

## GraphQL — Fleksibilitas Query

### N+1 Problem — Mengapa GraphQL Bisa LEBIH Lambat

```
SCHEMA:
type User {
  id: ID
  posts: [Post]  ← relasi
}

QUERY:
{
  users {           # Ambil 100 user
    id
    posts {         # Untuk SETIAP user, ambil posts
      title
    }
  }
}

TANPA DATALOADER — N+1 Queries ke Database:
Query 1: SELECT * FROM users          → 100 user
Query 2: SELECT * FROM posts WHERE user_id = 1
Query 3: SELECT * FROM posts WHERE user_id = 2
Query 4: SELECT * FROM posts WHERE user_id = 3
...
Query 101: SELECT * FROM posts WHERE user_id = 100

TOTAL: 101 queries untuk 100 user!
Ini yang bikin GraphQL bisa 10x LEBIH LAMBAT dari REST

DENGAN DATALOADER — Batched:
Query 1: SELECT * FROM users
Query 2: SELECT * FROM posts WHERE user_id IN (1,2,3,...,100)

TOTAL: 2 queries saja!

Implementasi DataLoader (Python, Strawberry):
import strawberry
from strawberry.dataloader import DataLoader
from typing import List

async def load_posts_for_users(user_ids: List[int]) -> List[List[Post]]:
    # Satu query untuk SEMUA user sekaligus
    all_posts = await db.query(
        "SELECT * FROM posts WHERE user_id = ANY($1)",
        user_ids
    )
    # Group by user_id
    posts_by_user = defaultdict(list)
    for post in all_posts:
        posts_by_user[post.user_id].append(post)

    return [posts_by_user[uid] for uid in user_ids]

posts_loader = DataLoader(load_fn=load_posts_for_users)

@strawberry.type
class User:
    id: int

    @strawberry.field
    async def posts(self) -> List[Post]:
        return await posts_loader.load(self.id)
        # DataLoader akan batch semua .load() yang terjadi dalam satu request
```

### Query Complexity — Mencegah Abuse

```
MASALAH:
GraphQL memperbolehkan client query apapun yang mereka mau
→ Nested query yang dalam bisa jadi "DoS attack"

{
  users {
    friends {
      friends {
        friends {
          friends {  # 4 level dalam = exponential DB query
            id
          }
        }
      }
    }
  }
}

SOLUSI: Query Cost Analysis

from graphql import GraphQLSchema
from graphql_query_complexity import QueriesComplexityValidator, SimpleEstimator

MAX_COMPLEXITY = 100  # Tentukan batas

def validate_complexity(schema, query):
    complexity = get_query_complexity(
        schema,
        query,
        estimators=[
            SimpleEstimator(default_complexity=1),
            # Relasi lebih mahal
            FieldEstimator(field="users.posts", complexity=5),
        ]
    )

    if complexity > MAX_COMPLEXITY:
        raise Exception(f"Query complexity {complexity} exceeds maximum {MAX_COMPLEXITY}")

# Tambah ke middleware GraphQL
```

### Kapan GraphQL Worth It

```
WORTH IT jika:
✅ Banyak client dengan kebutuhan data berbeda
   → Mobile: butuh field A, B, C
   → Web: butuh field A, B, C, D, E
   → Dengan REST: buat 2 endpoint atau overfetch
   → Dengan GraphQL: satu endpoint, client pilih field

✅ Rapid frontend iteration
   → Frontend bisa tambah field tanpa backend deployment
   → Self-documenting via introspection

✅ Aggregasi dari multiple data source
   → GraphQL stitching / federation

TIDAK WORTH IT jika:
❌ Simple CRUD API dengan sedikit client
❌ Public API (throttling lebih kompleks, persisted queries wajib)
❌ Tim backend kecil (overhead schema design + N+1 + complexity)
❌ High-performance real-time (WebSocket atau gRPC lebih cocok)
```

---

## Decision Matrix — Kapan Pakai Yang Mana

```
DIAGRAM KEPUTUSAN:

                 Real-time?
                 /        \
               YA          TIDAK
               │              │
         Bidirectional?   Many clients/
               │          different needs?
           /      \          /       \
         YA       TIDAK    YA        TIDAK
         │           │     │            │
      WebSocket   SSE/    GraphQL    Internal
                 Polling              service?
                              /            \
                            YA             TIDAK
                            │                │
                          gRPC             REST
```

| Kriteria                     | REST            | gRPC               | WebSocket         | GraphQL         |
| ---------------------------- | --------------- | ------------------ | ----------------- | --------------- |
| **Browser support langsung** | ✅ Native       | ❌ Butuh proxy     | ✅ Native         | ✅ Native       |
| **Caching built-in**         | ✅ HTTP cache   | ❌ Terbatas        | ❌ Tidak ada      | ⚠️ Hanya query  |
| **Real-time**                | ❌ Polling only | ⚠️ Streaming       | ✅ Native         | ⚠️ Subscription |
| **Binary efficiency**        | ❌ JSON         | ✅ Protobuf        | ⚠️ Frame overhead | ❌ JSON         |
| **Type safety**              | ⚠️ Manual       | ✅ .proto contract | ❌ Manual         | ✅ Schema       |
| **Debugging**                | ✅ curl/Postman | ❌ Butuh grpcurl   | ⚠️ Butuh tool     | ✅ Playground   |
| **Learning curve**           | ✅ Rendah       | 🔴 Tinggi          | 🟡 Medium         | 🟡 Medium       |
| **Scaling**                  | ✅ Stateless    | ✅                 | ❌ Stateful       | ✅              |
| **CDN friendly**             | ✅              | ❌                 | ❌                | ⚠️              |

### Use Case konkret

```
E-COMMERCE:
├── Product catalog API: REST (CDN cache, SEO friendly)
├── Search API: REST atau GraphQL (flexible query)
├── Inventory service→service: gRPC
├── Order notification ke client: WebSocket
└── Checkout: REST (idempotency key wajib)

CHAT APP:
├── Auth, user profile: REST
├── Message history: REST (cacheable)
└── Real-time messaging: WebSocket

GAME MULTIPLAYER:
├── Auth, leaderboard: REST
├── Game state sync: WebSocket (atau UDP via QUIC)
└── Matchmaking service: gRPC internal

FINTECH DASHBOARD:
├── Account data: REST
├── Live price feed: WebSocket (SSE alternatif)
├── Transaction service: REST + idempotency
└── Internal analytics pipeline: gRPC streaming
```

---

## Best Practices per Protokol

### REST Best Practices Checklist

```
API DESIGN:
☐ Gunakan HTTP status code yang benar (tidak semua 200)
☐ URL menggunakan noun bukan verb (/users bukan /getUsers)
☐ Versi API di URL (/v1/, /v2/)
☐ Response schema konsisten
☐ Error response menyertakan error_code yang bisa diprogram

PERFORMANCE:
☐ Implementasi caching dengan Cache-Control header
☐ Gunakan ETag untuk conditional requests
☐ Pagination dengan cursor (bukan offset untuk large data)
☐ Compression: gzip/br untuk response > 1KB
☐ Connection pooling untuk DB

SECURITY:
☐ Rate limiting per IP dan per user
☐ Authentication di setiap endpoint (kecuali yang public)
☐ Validate semua input (Pydantic, Joi, Zod)
☐ CORS yang strict (bukan *)
☐ HTTPS only, HSTS header
☐ Idempotency key untuk non-idempotent POST
```

### gRPC Best Practices Checklist

```
PROTO DESIGN:
☐ Gunakan snake_case untuk field names
☐ Selalu mulai dari field number 1 (jangan skip)
☐ Tandai field deprecated dengan [deprecated = true]
☐ Gunakan Any atau oneof untuk polymorphic field

PERFORMANCE:
☐ Connection pool: reuse channel, jangan buat baru per request
☐ Deadline/timeout di setiap RPC call
☐ Implement retry dengan exponential backoff

OBSERVABILITY:
☐ gRPC status code di setiap response
☐ Interceptor untuk logging dan metrics
☐ Distributed tracing (OpenTelemetry)

SECURITY:
☐ TLS mutual authentication (mTLS) untuk internal service
☐ Auth via metadata (bukan query param)
```

### WebSocket Best Practices Checklist

```
CONNECTION:
☐ Authenticate SEBELUM upgrade (atau di pesan pertama setelah connect)
☐ Implement heartbeat/ping-pong (setiap 30 detik)
☐ Detect stale connection dan close dari server side
☐ Client implement reconnection dengan exponential backoff

MESSAGE:
☐ Define message type/schema yang jelas (JSON dengan type field)
☐ Message size limit (cegah memory exhaustion)
☐ Sequence number untuk detect missed message

SCALING:
☐ Pub/Sub (Redis) untuk cross-server broadcast
☐ Sticky session atau distributed session storage
☐ Graceful shutdown: kirim CLOSE frame ke semua client

SECURITY:
☐ Validate origin header (CSRF via WebSocket)
☐ Rate limit per connection
☐ Encrypt payload jika data sensitif (walaupun sudah WSS)
```

### GraphQL Best Practices Checklist

```
SCHEMA:
☐ DataLoader untuk semua relasi (WAJIB)
☐ Query complexity limit
☐ Query depth limit
☐ Pagination untuk semua list type

PERFORMANCE:
☐ Persisted queries untuk production (hash-based, cegah arbitrary query)
☐ Response caching (per-query hash)
☐ APQ (Automatic Persisted Queries) untuk bandwidth saving

SECURITY:
☐ Disable introspection di production
☐ Field-level authorization (bukan hanya resolver level)
☐ Input validation + sanitization
☐ Rate limit berdasarkan query complexity, bukan jumlah request
```

---

## Kombinasi Pattern — Dunia Nyata

```
POLA UMUM YANG BENAR:

BACKEND FOR FRONTEND (BFF):
┌──────────┐   WebSocket    ┌─────┐
│  Browser │◄──────────────►│ BFF │◄── gRPC ──► Microservices
└──────────┘   REST/GraphQL └─────┘

BFF menghadap client dengan REST atau GraphQL
BFF berkomunikasi ke internal services via gRPC
Real-time updates ke client via WebSocket

EVENT-DRIVEN + REST:
REST   → synchronous read (GET /orders/123)
gRPC   → internal service call (inventory.CheckStock)
Events → Kafka/RabbitMQ untuk async processing
WebSocket → notify client bahwa order sudah ready

HYBRID CACHING:
                 ┌──── CDN (geografis) ─────────────────┐
Client ──────────► Load Balancer
                 └──── App Server ──► Redis ──► PostgreSQL
                        ↑
                   Stale-While-Revalidate:
                   Return cached (stale) data
                   sambil fetch fresh di background
```

---

> [!tip] Prioritas Belajar
> Urutan yang paling worth untuk web developer/DevOps:
>
> 1.  **REST yang benar** — 80% API di dunia ini REST. Banyak yang "REST-ish" tapi salah kaprah
> 2.  **WebSocket** — real-time adalah fitur yang semakin banyak diminta
> 3.  **GraphQL** — hanya jika ada multiple client dengan kebutuhan berbeda
> 4.  **gRPC** — saat mulai bangun microservice internal dengan traffic tinggi
>
> Jangan skip REST ke gRPC hanya karena "5ms lebih cepat". REST yang di-cache lebih cepat dari gRPC uncached.

---

## 🔗 Lihat Juga

- [[system-design|System Design]] — arsitektur yang menggunakan protokol ini
- [[cloud-infrastructure|Cloud Infrastructure]] — deployment dan service mesh (Istio untuk gRPC)
- [[ids-ips-waf-nsm-comparison|Security Tools]] — WAF untuk REST/GraphQL protection
- [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] — API security testing sebagai attack surface
- [[cicd-guide|CI/CD]] — API testing dalam pipeline

---

_API Protocols Deep Dive | REST (Caching, Idempotency) · gRPC (Protobuf, Streaming) · WebSocket (Reconnection, Scaling) · GraphQL (N+1, DataLoader, Complexity) · Decision Matrix_
