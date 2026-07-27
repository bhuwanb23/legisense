import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';

dotenv.config();

const app = express();
const port = Number(process.env.PORT) || 3001;

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'legisense-backend',
    timestamp: new Date().toISOString(),
  });
});

app.get('/', (_req, res) => {
  res.json({
    name: 'Legisense API',
    version: '1.0.0',
    docs: 'Routes will be added as features are rebuilt.',
  });
});

app.listen(port, () => {
  console.log(`Legisense API listening on http://localhost:${port}`);
});
