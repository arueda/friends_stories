import express from 'express';
import cors from 'cors';
import db from './db.js';

const app = express();
app.use(cors());
app.use(express.json());

// GET /api/users — list all users
app.get('/api/users', (req, res) => {
  const users = db.prepare('SELECT id, username, avatar_url FROM users ORDER BY id').all();
  res.json({ data: users });
});

// GET /api/stories — paginated stories grouped by user
app.get('/api/stories', (req, res) => {
  const page = Math.max(1, parseInt(req.query.page) || 1);
  const limit = Math.max(1, Math.min(50, parseInt(req.query.limit) || 10));
  const offset = (page - 1) * limit;

  // Get paginated users who have stories (ordered by most recent story)
  const users = db.prepare(`
    SELECT u.id, u.username, u.avatar_url
    FROM users u
    JOIN stories s ON s.user_id = u.id
    GROUP BY u.id
    ORDER BY MAX(s.created_at) DESC
    LIMIT ? OFFSET ?
  `).all(limit, offset);

  // Check if there are more users beyond this page (same join as above)
  const totalUsers = db.prepare(`
    SELECT COUNT(*) as count FROM (
      SELECT 1 FROM users u JOIN stories s ON s.user_id = u.id GROUP BY u.id
    )
  `).get().count;
  const hasMore = offset + limit < totalUsers;

  // Fetch all stories for these users
  const getStories = db.prepare(`
    SELECT id, image_url, caption, created_at
    FROM stories
    WHERE user_id = ?
    ORDER BY created_at DESC
  `);

  const data = users.map(user => ({
    user: { id: user.id, username: user.username, avatar_url: user.avatar_url },
    stories: getStories.all(user.id),
  }));

  res.json({ data, page, limit, hasMore });
});

// POST /api/stories — create a new story
app.post('/api/stories', (req, res) => {
  const { user_id, image_url, caption } = req.body;

  if (!user_id || !image_url) {
    return res.status(400).json({ error: 'user_id and image_url are required' });
  }

  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(user_id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  const result = db.prepare(
    'INSERT INTO stories (user_id, image_url, caption) VALUES (?, ?, ?)'
  ).run(user_id, image_url, caption || null);

  const story = db.prepare('SELECT * FROM stories WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json({ data: story });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Stories API running on http://localhost:${PORT}`);
});
