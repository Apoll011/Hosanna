import express from 'express';
import path from 'path';
import fs from 'fs/promises';
import cors from 'cors';
import { createServer as createViteServer } from 'vite';

const app = express();
const PORT = 3000;
const SECURITY_TOKEN = process.env.SYNC_API_TOKEN || 'test-token-123';

const DATA_DIR = path.join(process.cwd(), 'data');
const SONGS_DIR = path.join(DATA_DIR, 'songs');
const SERVICES_FILE = path.join(DATA_DIR, 'services.json');

app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Ensure data directories exist
async function initDataDirs() {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true });
    await fs.mkdir(SONGS_DIR, { recursive: true });
    
    // Seed a service file if it doesn't exist
    try {
      await fs.access(SERVICES_FILE);
    } catch {
      await fs.writeFile(SERVICES_FILE, JSON.stringify([], null, 2), 'utf-8');
    }
  } catch (err) {
    console.error('Failed to initialize data directories:', err);
  }
}

// Helper to read files recursively
async function getFilesRecursively(dir: string): Promise<string[]> {
  const dirents = await fs.readdir(dir, { withFileTypes: true });
  const files = await Promise.all(dirents.map((dirent) => {
    const res = path.resolve(dir, dirent.name);
    return dirent.isDirectory() ? getFilesRecursively(res) : [res];
  }));
  return Array.prototype.concat(...files);
}

// Middleware de Autenticação
function authenticate(req: express.Request, res: express.Response, next: express.NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de segurança ausente ou inválido.' });
  }
  const token = authHeader.split(' ')[1];
  if (token !== SECURITY_TOKEN) {
    return res.status(403).json({ error: 'Acesso negado. Token incorreto.' });
  }
  next();
}

// API Routes
app.post('/api/sync', authenticate, async (req, res) => {
  try {
    const { services: clientServices } = req.body;

    // 1. Process files (Songs)
    const allFilePaths = await getFilesRecursively(SONGS_DIR);
    const files = await Promise.all(
      allFilePaths.map(async (fullPath) => {
        const stats = await fs.stat(fullPath);
        const relativePath = path.relative(SONGS_DIR, fullPath).replace(/\\/g, '/');
        const content = await fs.readFile(fullPath, 'utf-8');
        return {
          path: relativePath,
          content,
          updatedAt: stats.mtimeMs
        };
      })
    );

    // Filter out non-chopro files just in case
    const choproFiles = files.filter(f => f.path.endsWith('.chopro') || f.path.endsWith('.cho') || f.path.endsWith('.txt'));

    // 2. Process Services
    let serverServices: any[] = [];
    try {
      const servicesContent = await fs.readFile(SERVICES_FILE, 'utf-8');
      serverServices = JSON.parse(servicesContent);
    } catch (e) {
      serverServices = [];
    }

    if (clientServices && Array.isArray(clientServices)) {
      // Merge received services
      clientServices.forEach((clientSvc) => {
        const idx = serverServices.findIndex(s => s.id === clientSvc.id);
        if (idx !== -1) {
          serverServices[idx] = clientSvc; // Overwrite
        } else {
          serverServices.push(clientSvc); // Add new
        }
      });
      // Save back to db
      await fs.writeFile(SERVICES_FILE, JSON.stringify(serverServices, null, 2), 'utf-8');
    }

    res.json({
      files: choproFiles,
      services: serverServices
    });
  } catch (error: any) {
    console.error('Sync Error:', error);
    res.status(500).json({ error: 'Internal Server Error', details: error.message });
  }
});

app.post('/api/save_song', authenticate, async (req, res) => {
  try {
    const { path: songPath, content } = req.body;
    if (!songPath) return res.status(400).json({ error: 'Path is required' });
    
    // Security check to prevent writing outside SONGS_DIR
    const safePath = path.normalize(songPath).replace(/^(\.\.(\/|\\|$))+/, '');
    const fullPath = path.join(SONGS_DIR, safePath);
    
    await fs.mkdir(path.dirname(fullPath), { recursive: true });
    await fs.writeFile(fullPath, content, 'utf-8');
    res.json({ success: true });
  } catch (err: any) {
    console.error('Save Error:', err);
    res.status(500).json({ error: 'Failed to save song', details: err.message });
  }
});

app.delete('/api/delete_song', authenticate, async (req, res) => {
  try {
    const { path: songPath } = req.body;
    if (!songPath) return res.status(400).json({ error: 'Path is required' });
    
    // Security check to prevent deleting outside SONGS_DIR
    const safePath = path.normalize(songPath).replace(/^(\.\.(\/|\\|$))+/, '');
    const fullPath = path.join(SONGS_DIR, safePath);
    
    try {
      await fs.unlink(fullPath);
    } catch (e: any) {
      if (e.code !== 'ENOENT') throw e; // ignore if already deleted
    }
    
    res.json({ success: true });
  } catch (err: any) {
    console.error('Delete Error:', err);
    res.status(500).json({ error: 'Failed to delete song', details: err.message });
  }
});

async function startServer() {
  await initDataDirs();

  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://localhost:${PORT}`);
  });
}

startServer();
