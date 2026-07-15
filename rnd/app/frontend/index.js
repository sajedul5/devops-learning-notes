const express = require("express");
const axios = require("axios");
const app = express();

const API_URL = process.env.API_URL || "http://api.local";

app.get("/", async (req, res) => {
  try {
    const response = await axios.get(`${API_URL}/api`);
    res.send(`
      <h1>🚀 Welcome to App (Canary)</h1>
      <p>New UI test version</p>
      <p>API Response: ${response.data.message}</p>
    `);
  } catch (err) {
    res.send("API not reachable ❌");
  }
});

app.get("/health", (req, res) => {
  res.json({ status: "UP" });
});

app.listen(3000);