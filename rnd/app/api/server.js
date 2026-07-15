const express = require("express");
const app = express();

app.get("/api", (req, res) => {
  res.json({ message: "Backend OK 🚀" });
});

// 🟢 health check
app.get("/health", (req, res) => {
  res.status(200).json({ status: "UP" });
});

// 🟡 readiness check
app.get("/ready", (req, res) => {
  res.status(200).json({ status: "READY" });
});

app.listen(4000, () => console.log("Backend running"));