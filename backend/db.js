import Database from 'better-sqlite3';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const db = new Database(join(__dirname, 'stories.db'));

// Enable WAL mode for better performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    avatar_url TEXT
  );

  CREATE TABLE IF NOT EXISTS stories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id),
    image_url TEXT NOT NULL,
    caption TEXT,
    created_at TEXT DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
  );
`);

// Seed data if tables are empty
const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;

if (userCount === 0) {
  const insertUser = db.prepare('INSERT INTO users (username, avatar_url) VALUES (?, ?)');
  const insertStory = db.prepare('INSERT INTO stories (user_id, image_url, caption) VALUES (?, ?, ?)');

  const seed = db.transaction(() => {
    insertUser.run('alice', 'https://i.pravatar.cc/150?u=alice');
    insertUser.run('bob', 'https://i.pravatar.cc/150?u=bob');
    insertUser.run('carol', 'https://i.pravatar.cc/150?u=carol');
    insertUser.run('dave', 'https://i.pravatar.cc/150?u=dave');

    insertStory.run(1, 'https://picsum.photos/seed/a1/400/700', 'Morning coffee');
    insertStory.run(1, 'https://picsum.photos/seed/a2/400/700', 'Sunset walk');
    insertStory.run(2, 'https://picsum.photos/seed/b1/400/700', 'At the gym');
    insertStory.run(2, 'https://picsum.photos/seed/b2/400/700', null);
    insertStory.run(3, 'https://picsum.photos/seed/c1/400/700', 'New recipe');
    insertStory.run(3, 'https://picsum.photos/seed/c2/400/700', 'Book club');
    insertStory.run(3, 'https://picsum.photos/seed/c3/400/700', null);
    insertStory.run(4, 'https://picsum.photos/seed/d1/400/700', 'Road trip!');
  });

  seed();
  console.log('Database seeded with sample data');
}

export default db;
