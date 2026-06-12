# Human Design — Security-First Reference

## Why Security Matters Here

Human Design tools collect **sensitive personal data**: birth date, birth time, birth location. This data is:

- Personally identifiable (can narrow identity when combined)
- Culturally sensitive (spiritual/belief-system context)
- Potentially aggregated for profiling if mishandled

Apply these security standards for **all** interactive HD tools.

---

## Input Validation (All Fields)

### Birth Date

```javascript
function validateBirthDate(dateStr) {
  // Sanitize: strip all non-date characters
  const sanitized = dateStr.replace(/[^0-9\-\/\.]/g, "")

  const date = new Date(sanitized)
  const now = new Date()
  const minDate = new Date("1900-01-01")

  if (isNaN(date.getTime())) throw new Error("Invalid date format")
  if (date > now) throw new Error("Birth date cannot be in the future")
  if (date < minDate) throw new Error("Date out of supported range")

  return date
}
```

### Birth Time

```javascript
function validateBirthTime(timeStr) {
  // Accept HH:MM or HH:MM:SS, 24hr format
  const pattern = /^([01]?\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/
  if (!pattern.test(timeStr.trim())) {
    throw new Error("Invalid time format (use HH:MM)")
  }
  return timeStr.trim()
}
```

### Location / City Input

```javascript
function validateLocation(input) {
  // Strip HTML tags and script injections
  const stripped = input.replace(/<[^>]*>/g, "").trim()

  // Max length guard
  if (stripped.length > 100) throw new Error("Location too long")

  // Block obvious injection attempts
  const suspicious = /[<>{}"'%;()=+\[\]\\]/g
  if (suspicious.test(stripped)) throw new Error("Invalid characters in location")

  return stripped
}
```

---

## XSS Prevention

**NEVER** use `innerHTML` with user input.

```javascript
// ❌ DANGEROUS
element.innerHTML = userInput

// ✅ SAFE — always use textContent for user data
element.textContent = userInput

// ✅ SAFE — for structured output, sanitize first
function safeHTML(str) {
  const div = document.createElement("div")
  div.textContent = str
  return div.innerHTML // Now HTML-entity encoded
}
```

### React / JSX

JSX auto-escapes by default. Avoid `dangerouslySetInnerHTML` unless source is trusted and sanitized via DOMPurify.

---

## Data Storage Policy

### Principle: Minimum Retention

Birth data should exist **only** for the duration of chart calculation. After the chart renders:

- Clear form fields
- Do not persist to `localStorage` or `sessionStorage` without explicit user consent
- Do not send to third-party analytics with birth data attached

### If Persistence Is Needed (User Explicitly Saves)

```javascript
// Only store with explicit user action (Save My Chart button)
// Encrypt before storage — never plaintext PII in localStorage
async function saveChartSecurely(chartData) {
  // Hash or anonymize birth data before storage
  const anonymized = {
    type: chartData.type,
    authority: chartData.authority,
    profile: chartData.profile,
    // Store only the result, NOT raw birth date/time/location
    generatedAt: new Date().toISOString(),
  }
  localStorage.setItem("hd_chart", JSON.stringify(anonymized))
}
```

---

## Content Security Policy

Add these headers in deployment (include as comment in HTML for developer reference):

```html
<!--
  DEPLOYMENT SECURITY HEADERS — configure on your server:
  
  Content-Security-Policy: 
    default-src 'self';
    script-src 'self' 'nonce-{random}';
    style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
    font-src 'self' https://fonts.gstatic.com;
    connect-src 'self' [your-api-domain];
    img-src 'self' data:;
    frame-ancestors 'none';
  
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(), camera=(), microphone=()
-->
```

---

## API & External Services

### When Using Geocoding APIs (for birth location)

```javascript
// Always use HTTPS endpoints only
// Validate API response before trusting
async function geocodeLocation(locationStr) {
  // Sanitize input before sending to API
  const safe = validateLocation(locationStr)

  try {
    const response = await fetch(`https://[your-api].com/geocode?q=${encodeURIComponent(safe)}`, {
      method: "GET",
      headers: { Accept: "application/json" },
    })

    if (!response.ok) throw new Error(`Geocode failed: ${response.status}`)

    const data = await response.json()

    // Validate response shape — never trust raw API data
    if (!data.lat || !data.lon) throw new Error("Invalid geocode response")

    // Clamp coordinates to valid range
    const lat = Math.max(-90, Math.min(90, parseFloat(data.lat)))
    const lon = Math.max(-180, Math.min(180, parseFloat(data.lon)))

    return { lat, lon }
  } catch (err) {
    throw new Error("Location lookup failed — please try again")
  }
}
```

### Rate Limiting (Client-Side Guard)

```javascript
// Prevent API abuse / rapid resubmission
let lastSubmit = 0
const RATE_LIMIT_MS = 3000 // 3 seconds between submissions

function rateLimitedSubmit(handler) {
  const now = Date.now()
  if (now - lastSubmit < RATE_LIMIT_MS) {
    showError("Please wait a moment before generating another chart.")
    return
  }
  lastSubmit = now
  handler()
}
```

---

## Privacy Disclosure (Required UI Element)

Any tool collecting birth data MUST include a visible disclosure:

```html
<p class="privacy-notice" role="note">
  🔒 Your birth data is used only to generate your chart and is not stored or shared.
  <a href="/privacy">Privacy Policy</a>
</p>
```

Style this notice to be legible (not hidden in fine print).

---

## Error Handling (Security-Safe)

**Never expose technical internals in error messages:**

```javascript
// ❌ EXPOSES stack trace / system info
catch (err) {
  showError(err.message); // Could be: "DB connection failed at line 234..."
}

// ✅ User-friendly, safe error messages only
catch (err) {
  console.error('[HD Chart Error]', err); // Log internally only
  showError('Something went wrong. Please check your inputs and try again.');
}
```

---

## Security Checklist

Before shipping any interactive Human Design tool:

- [ ] All inputs validated (date, time, location)
- [ ] No `innerHTML` with user data
- [ ] Birth data NOT stored in localStorage without explicit user consent
- [ ] CSP headers documented in code comments
- [ ] API calls use `encodeURIComponent()` on user input
- [ ] Rate limiting on form submission
- [ ] Privacy disclosure visible to user
- [ ] Error messages are user-friendly (no stack traces exposed)
- [ ] HTTPS assumed for all external requests
- [ ] No third-party tracking scripts injected without disclosure
