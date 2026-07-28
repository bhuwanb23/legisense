import type { Config } from 'drizzle-kit';

export default {
  schema: './src/models/*',
  out: './drizzle',
  dialect: 'sqlite',
  dbCredentials: {
    url: './data/legisense.db',
  },
} satisfies Config;
