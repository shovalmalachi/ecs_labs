const http = require("http");

const PORT = process.env.PORT || 3000;

const VERSION = process.env.VERSION || "v1";

const SERVICE =
  process.env.SERVICE_NAME ||
  process.env.SPRING_APPLICATION_NAME ||
  "devops-lab";

const PROFILE =
  process.env.SPRING_PROFILES_ACTIVE ||
  process.env.PROFILE ||
  "default";

const server = http.createServer((req, res) => {

  if (req.url === "/health") {
    res.writeHead(200);
    return res.end("ok");
  }

  res.writeHead(200, {
    "Content-Type": "application/json"
  });

  res.end(JSON.stringify({
    service: SERVICE,
    version: VERSION,
    spring_profile: PROFILE
  }));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});