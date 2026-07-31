# Backend

```bash
npm install
cp .env.example .env
npm run dev
```

`GET /health` → `{ status: "ok" }`

## Local AI (Ollama)

Preferred provider for analysis is local Ollama (`llama3.2:1b`):

```bash
ollama pull llama3.2:1b
# ensure Ollama is running, then set in .env:
# OLLAMA_ENABLED=true
```

Upload saves the document only (`202`). Analyze with a single blocking call:

`POST /api/documents/:id/process`

## Optional MarkItDown extract

For richer Office/PDF text extraction:

```bash
pip install markitdown
```

If the CLI is missing, the API falls back to pdf-parse / mammoth / Tesseract.
