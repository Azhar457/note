---
title: "Frontend Engineering — React, Next.js, Component Architecture & State Management"
tags:
  - frontend
  - react
  - next-js
  - component-architecture
  - state-management
  - library
aliases:
  - "frontend-engineering-guide"
  - "react-architecture-patterns"
  - "frontend-react-nextjs"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# ⚛️ Frontend Engineering — React, Next.js, Component Architecture & State Management

> Vault belum punya catatan soal frontend engineering sama sekali — padahal elo manage beberapa repo Next.js di [REDACTED] (FE untuk asia-be, insite-be, dri-triplet-be). Catatan ini mengisi celah fundamental: component architecture patterns di React, state management (dari useState sampai Zustand/Redux), rendering strategy (CSR vs SSR vs SSG vs ISR vs RSC), CSS architecture, dan Next.js App Router vs Pages Router. Tanpa fondasi ini, frontend codebase cenderung jadi spaghetti component dengan state yang bocor ke mana-mana.

> [!info] Posisi di Vault
> Ini adalah domain **baru** di vault — Frontend Engineering. Terkait dengan [[software-engineering]] (prinsip software umum), [[clean-code-robert-martin]] (code quality), [[api-security-deep-dive]] (frontend security), [[cicd-guide]] (frontend CI/CD), dan [[web-security]] (XSS/CSP).

---

## Daftar Isi

- [[#1. Component Architecture — Composition over Inheritance]]
- [[#2. State Management — Local sampai Global]]
- [[#3. Rendering Patterns — CSR, SSR, SSG, ISR, RSC]]
- [[#4. Performance — Bundle, Core Web Vitals, Virtualisasi]]
- [[#5. CSS Architecture — Modules, Tailwind, Design System]]
- [[#6. Next.js — App Router vs Pages Router]]
- [[#7. Testing — Unit, Integration, E2E]]
- [[#8. Build & Deploy — Vite, Turbopack, Docker]]
- [[#9. Error Handling & Monitoring]]
- [[#10. Security — XSS, CSP, Auth Patterns]]
- [[🔗 Koneksi ke Catatan Lain]]
- [[✅ Checklist]]
- [[Roadmap Belajar]]

---

## 1. Component Architecture — Composition over Inheritance

### 1.1 Evolution of React Patterns

```
2014: Mixins (deprecated)
2015: createClass → ES6 class components
2016: Higher-Order Components (HOC) — withRouter(), connect()
2018: Render Props — <DataProvider render={...} />
2019: Hooks — useState, useEffect, custom hooks ← TODAY's default
2021: Server Components (RSC) — async component, zero client JS
2024+: React Server Components (stable) + Server Actions
```

### 1.2 Modern Component Patterns

| Pattern                      | Kapan Dipakai                           | Contoh                                                    |
| :--------------------------- | :-------------------------------------- | :-------------------------------------------------------- |
| **Atomic Design**            | Design system skala besar               | atoms → molecules → organisms → templates → pages         |
| **Compound Components**      | Component dengan internal state sharing | `<Select>` → `<Select.Option>`, `<Select.Label>`          |
| **Container/Presentational** | Pisah logic dari UI                     | Container: fetching + state → Presentational: render only |
| **Custom Hooks**             | Reusable stateful logic                 | `useAuth()`, `useDebounce()`, `useWebSocket()`            |
| **Render Props**             | Behavior sharing tanpa state            | `<MouseTracker render={(pos) => ...} />`                  |
| **Slots (children)**         | Layout injection                        | `<Card header={<Header/>} footer={<Footer/>}>`            |

### 1.3 Component Composition Examples

```tsx
// Atomic Design: Molecule
interface InputFieldProps {
  label: string
  error?: string
  icon?: React.ReactNode
}

function InputField({ label, error, icon }: InputFieldProps) {
  return (
    <div className="input-field">
      <label className="input-field__label">{label}</label>
      <div className="input-field__wrapper">
        {icon && <span className="input-field__icon">{icon}</span>}
        <input className={`input-field__input ${error ? "input-field__input--error" : ""}`} />
      </div>
      {error && <span className="input-field__error">{error}</span>}
    </div>
  )
}

// Compound Component: Tabs
function Tabs({ children }: { children: React.ReactNode }) {
  const [active, setActive] = useState(0)
  return (
    <TabsContext.Provider value={{ active, setActive }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  )
}
Tabs.List = function List({ children }: { children: React.ReactNode }) {
  return <div className="tabs__list">{children}</div>
}
Tabs.Panel = function Panel({ index, children }: { index: number; children: React.ReactNode }) {
  const { active } = useContext(TabsContext)
  return active === index ? <div className="tabs__panel">{children}</div> : null
}
```

### 1.4 Component Design Principles

```
Single Responsibility — Satu component, satu tanggung jawab
  ✅ <UserProfileCard>
  ❌ <UserProfileCardAndSettingsAndNotifications>

Props API Design:
  ✅ Explicit props: <Button variant="primary" size="md" disabled>
  ❌ Config object: <Button config={{ variant: 'primary', size: 'md' }}>

Don't Repeat Yourself:
  Extract repeated JSX + logic → custom component + custom hook

You Aren't Gonna Need It (YAGNI):
  Jangan bikin generic component yang bisa handle 100 use case
  Kalau cuma dipake di 2 tempat, hardcode aja dulu
```

---

## 2. State Management — Local sampai Global

### 2.1 State Categories

| Category            | Contoh                        | Solusi                            |
| :------------------ | :---------------------------- | :-------------------------------- |
| **Local UI state**  | Modal open/close, form input  | `useState`, `useReducer`          |
| **Server state**    | Data dari API (users, orders) | TanStack Query, SWR               |
| **Global UI state** | Theme, sidebar collapse       | Zustand, Jotai, Context           |
| **URL state**       | Search params, filters        | `useSearchParams`, Next.js router |
| **Form state**      | Form values, validation       | React Hook Form, Formik           |

### 2.2 State Management Tool Comparison

| Tool               | Bundle Size |   Boilerplate   |  Performance   | DevTools | Best For                   |
| :----------------- | :---------: | :-------------: | :------------: | :------: | :------------------------- |
| **useState**       |    0 KB     |     Minimal     |       🟢       |    ❌    | Local component state      |
| **useReducer**     |    0 KB     |     Sedang      |       🟢       |    ❌    | Complex local state        |
| **Context API**    |    0 KB     |     Minimal     | 🟡 (re-render) |    ❌    | Low-frequency global state |
| **Zustand**        |   1.1 KB    |     Minimal     |       🟢       |    ✅    | Medium global state        |
| **Jotai**          |   3.3 KB    |     Minimal     |  🟢 (atomic)   |    ✅    | Atomic derived state       |
| **Redux Toolkit**  |    11 KB    | Tinggi (slices) |       🟢       |    ✅    | Large-scale global state   |
| **TanStack Query** |    13 KB    |     Minimal     |      🟢🟢      |    ✅    | Server state (API cache)   |

### 2.3 Practical Recommendations

```text
Small app / MVP:
  useState + Context + TanStack Query → cukup untuk 95% kasus

Medium app (dashboard admin):
  Zustand untuk UI state + TanStack Query untuk server state
  → Zustand: < 1KB, no boilerplate, no Provider wrapping

Large app (enterprise, 50+ pages):
  Redux Toolkit + RTK Query — boilerplate tinggi
  Tapi devtools, middleware, ecosystem sepadan untuk skala tim besar

Rules of thumb:
  - Kalau state cuma dipake 1 component → useState
  - Kalau dipake 2-3 sibling → lifted state atau Context
  - Kalau dipake banyak component di beda branch → Zustand/Redux
  - Query param state → URL search params (bisa di-share via link)
```

---

## 3. Rendering Patterns — CSR, SSR, SSG, ISR, RSC

### 3.1 Comparison Matrix

| Pattern                        |  Render Location  | First Paint  |   SEO   |   TTFB    |   Interactivity    |     Fresh Data      |
| :----------------------------- | :---------------: | :----------: | :-----: | :-------: | :----------------: | :-----------------: |
| **CSR** (Create React App)     |      Browser      |   🟡 Slow    | ❌ Bad  |  🟢 Fast  |      🟢 Fast       |   🟢 Always fresh   |
| **SSR** (Next.js Pages Router) | Server + Browser  |   🟢 Fast    | ✅ Good | 🟡 Slower | 🟡 Hydration delay |   🟡 Per request    |
| **SSG** (static export)        |    Build time     | 🟢🟢 Instant | ✅ Best |  🟢 Fast  |      🟢 Fast       | ❌ Stale on deploy  |
| **ISR** (Incremental)          | Build + on-demand |   🟢 Fast    | ✅ Best |  🟢 Fast  |      🟢 Fast       | 🟡 Revalidation lag |
| **RSC** (App Router)           |      Server       |   🟢 Fast    | ✅ Best |  🟢 Fast  |      🟢 Fast       |   🟢 Per request    |

### 3.2 Next.js Rendering Decision

```typescript
// App Router — per-page rendering strategy
// Static (SSG) — data gak pernah berubah
export const dynamic = "force-static"

// Dynamic (SSR) — data per request
export const dynamic = "force-dynamic"

// ISR — revalidate setiap N detik
export const revalidate = 3600 // 1 jam

// Streaming SSR — progressive rendering
export const dynamic = "auto"
export const experimental = { streaming: true }
```

### 3.3 React Server Components (RSC)

```tsx
// Server Component — zero client JS, direct DB access
async function ProductList() {
  const products = await db.query("SELECT * FROM products")
  return (
    <div>
      {products.map((p) => (
        <ProductCard key={p.id} product={p} />
      ))}
    </div>
  )
}

// Client Component — interactivity, hooks
;("use client")
function AddToCart({ productId }: { productId: string }) {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount((c) => c + 1)}>Add ({count})</button>
}

// Mix RSC + Client Component
async function ProductPage({ params }: { params: { id: string } }) {
  const product = await fetchProduct(params.id)
  return (
    <div>
      <ProductInfo product={product} /> {/* Server Component */}
      <ClientWrapper>
        {" "}
        {/* Wrapper client */}
        <ProductReviews productId={params.id} />
        <AddToCart productId={params.id} /> {/* Client Component */}
      </ClientWrapper>
    </div>
  )
}
```

---

## 4. Performance — Bundle, Core Web Vitals, Virtualisasi

### 4.1 Core Web Vitals

| Metric                      | Target        | Cara Capai                                                          |
| :-------------------------- | :------------ | :------------------------------------------------------------------ |
| **LCP** (Loading)           | < 2.5s        | Optimize images, preload fonts, minimize render-blocking            |
| **FID/INP** (Interactivity) | < 100ms/200ms | Code splitting, lazy hydration, debounce handlers                   |
| **CLS** (Visual Stability)  | < 0.1         | Set image/video dimensions, avoid layout shift from dynamic content |

### 4.2 Bundle Optimization

```typescript
// Dynamic import — code splitting
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,  // client-only
});

// Route-based splitting (Next.js automatic)
// pages/dashboard.tsx → dashboard.[hash].js
// pages/settings.tsx → settings.[hash].js

// Tree shaking — import specifik, bukan seluruh library
// ❌ import { Button } from 'antd';  // import seluruh antd
// ✅ import Button from 'antd/es/button';  // import specifik
```

### 4.3 Virtualisasi untuk Long List

```tsx
// react-window untuk 10,000+ items
import { FixedSizeList } from "react-window"

function VirtualList({ items }: { items: Item[] }) {
  return (
    <FixedSizeList height={600} itemCount={items.length} itemSize={50} outerRef={listRef}>
      {({ index, style }) => <div style={style}>{items[index].name}</div>}
    </FixedSizeList>
  )
}
```

---

## 🔗 Koneksi ke Catatan Lain

| Catatan                      | Koneksi                              |
| :--------------------------- | :----------------------------------- |
| [[software-engineering]]     | Prinsip software umum untuk frontend |
| [[clean-code-robert-martin]] | Code quality dan refactoring         |
| [[web-security]]             | XSS, CSP, CSRF prevention            |
| [[api-security-deep-dive]]   | Frontend-backend security boundary   |
| [[cicd-guide]]               | CI/CD pipeline untuk FE              |
| [[http-protocol-deepdive]]   | HTTP caching, headers                |

---

## ✅ Checklist

- [ ] Paham perbedaan CSR, SSR, SSG, ISR, RSC
- [ ] Bisa milih state management tool yang tepat
- [ ] Paham component composition patterns
- [ ] Bisa optimasi Core Web Vitals
- [ ] Paham Next.js App Router vs Pages Router
- [ ] Bisa setup testing (Jest + RTL + Playwright)
- [ ] Paham CSS architecture (Module, Tailwind, CSS-in-JS)

---

## Roadmap Belajar

```
HARI 1: Component Architecture
  - Baca catatan ini sampai selesai
  - Audit component di project Next.js lo — mana yang perlu refactor
  - Implementasi compound component pattern

HARI 2: Rendering Strategy
  - Audit halaman di project: mana yang butuh SSR, SSG, ISR
  - Testing: performance diff antara CSR dan SSR

HARI 3: State Management
  - Migrasi satu page dari Context ke Zustand
  - Setup TanStack Query untuk server state

HARI 4: Performance
  - Lighthouse audit project lo
  - Optimasi LCP/CLS/INP

HARI 5: Testing
  - Setup Jest + RTL untuk component test
  - Setup Playwright untuk E2E critical path
```

> [!warning] Bottom Line
> Frontend engineering bukan cuma "bikin komponen React". Kenalan dengan rendering strategy, state management, dan performance optimization bakal nentuin apakah aplikasi lo terasa cepat atau nge-lag di production. Next.js App Router dengan RSC adalah default yang baik untuk 2026 — tapi paham fundamental rendering patterns tetap penting biar gak salah pilih strategy untuk use case yang beda.

> [!tip] Lanjutan
> Catatan ini fokus ke React/Next.js. Ekosistem frontend juga mencakup Vue/Nuxt, Svelte/SvelteKit, dan Solid.js — topik untuk catatan terpisah. Juga terkait: [[software-engineering]] (prinsip umum), [[web-security]] (frontend security).
