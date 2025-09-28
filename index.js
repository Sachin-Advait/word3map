const express = require("express");
const bodyParser = require("body-parser");
const { v4: uuidv4 } = require("uuid");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Demo storage
const users = [];
const notifications = [];

/**
 * API 1: Create a user
 * POST /users
 * Body: { name: string }
 */
app.post("/users", (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: "Name is required" });

  // Check if user already exists (case-insensitive)
  const existingUser = users.find(
    (u) => u.name.toLowerCase() === name.toLowerCase()
  );
  if (existingUser) {
    return res.json({ message: "User exists", user: existingUser });
  }

  // Create new user
  const user = { id: uuidv4(), name };
  users.push(user);

  res.json({ message: "User created", user });
});

/**
 * API 2: Get all users
 * GET /users
 */
app.get("/users", (req, res) => {
  res.json(users);
});

/**
 * API 3: Send notification
 * POST /notifications
 * Body: { userIds: [string], message: string }
 */
app.post("/notifications", (req, res) => {
  const { senderId, userIds, message } = req.body;

  // Validate input
  if (!senderId || !userIds || !message) {
    return res
      .status(400)
      .json({ error: "senderId, userIds, and message are required" });
  }

  // Find the sender in users list
  const sender = users.find((u) => u.id === senderId);
  if (!sender) {
    return res.status(400).json({ error: "Invalid senderId (user not found)" });
  }

  // Filter out only valid receivers
  const validUserIds = userIds.filter((id) => users.find((u) => u.id === id));
  if (validUserIds.length === 0) {
    return res.status(400).json({ error: "No valid userIds provided" });
  }

  // Create notifications
  validUserIds.forEach((id) => {
    const receiver = users.find((u) => u.id === id);
    notifications.push({
      id: uuidv4(),
      userId: id, // receiver
      receiverName: receiver.name,
      senderId: sender.id, // sender
      senderName: sender.name, // store name for quick lookup
      message,
      read: false,
      createdAt: new Date(),
    });
  });

  res.json({ message: "Notifications sent" });
});

/**
 * API 4: Get notifications for a user
 * GET /notifications/:userId
 */
app.get("/notifications/:userId", (req, res) => {
  const { userId } = req.params;
  const userNotifs = notifications.filter((n) => n.userId === userId);
  res.json(userNotifs);
});

/**
 * Mark notification as read
 * POST /notifications/:notifId/read
 */
app.post("/notifications/:notifId/read", (req, res) => {
  const { notifId } = req.params;
  const notif = notifications.find((n) => n.id === notifId);
  if (!notif) return res.status(404).json({ error: "Notification not found" });

  notif.read = true;
  res.json({ message: "Notification marked as read", notif });
});

app.get("/open", (req, res) => {
  const words = req.query.words;
  if (!words) return res.status(400).send("Missing words parameter");

  // Return HTML that tries to open the app
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>Open GIS Map</title>
      </head>
      <body>
        <script>
          // Attempt to open the app
          window.location = "gismap://location?words=${encodeURIComponent(
            words
          )}";

          // Optional: fallback after 1 second to web page if app not installed
          setTimeout(() => {
            window.location = "https://word3map.onrender.com/web-map?words=${encodeURIComponent(
              words
            )}";
          }, 1000);
        </script>
        <p>If nothing happens, <a href="https://word3map.onrender.com/web-map?words=${encodeURIComponent(
          words
        )}">click here</a> to open in browser.</p>
      </body>
    </html>
  `);
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
