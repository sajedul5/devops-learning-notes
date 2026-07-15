const express = require("express");
const axios = require("axios");

const app = express();

const API_URL = process.env.API_URL || "http://api.local";

app.get("/", async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/api`);

    res.send(`
      <h1 style="color:green;">🟢 GREEN VERSION (v2)</h1>
      <p>NEW UI RELEASE 🚀</p>
      <button onclick="alert('New Feature Activated')">
        Click Me
      </button>
      <p>API: ${response.data.message}</p>
    `);

  } catch (err) {
    res.send("API not reachable ❌");
  }
});

app.get("/health", (req, res) => {
  res.json({ status: "UP", version: "green" });
});

app.listen(3000);