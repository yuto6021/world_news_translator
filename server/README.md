DeepL proxy sample

This is a minimal Express server that forwards translation requests to DeepL.

Usage:

1. Create a `.env` in this `server/` folder with:

DEEPL_KEY=0d528a61-d312-4a5e-9096-cbbddbb17eb0:fx
DEEPL_URL=https://api-free.deepl.com/v2/translate
PORT=3000

2. Install and start:

npm install
npm start

3. In the Flutter app, set `DEEPL_PROXY` in the client `.env` to `http://<server-host>:3000/translate` so the client will call the proxy instead of DeepL directly.

Security: keep your DEEPL_KEY on the server only — do NOT commit it to the repo.
