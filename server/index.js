require('dotenv').config();
const express = require('express');
const fetch = require('node-fetch');
const app = express();
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

const DEEPL_URL = process.env.DEEPL_URL || 'https://api-free.deepl.com/v2/translate';
const DEEPL_KEY = process.env.DEEPL_KEY; // set this in server .env (not in client)

if (!DEEPL_KEY) {
    console.warn('DEEPL_KEY is not set in server .env. Set it to forward requests.');
}

app.post('/translate', async (req, res) => {
    try {
        const { text, target_lang } = req.body;
        const body = new URLSearchParams();
        body.append('auth_key', DEEPL_KEY || '');
        body.append('text', text || '');
        body.append('target_lang', target_lang || 'JA');

        const r = await fetch(DEEPL_URL, {
            method: 'POST',
            body: body
        });
        const textBody = await r.text();
        res.status(r.status).send(textBody);
    } catch (e) {
        console.error('proxy error', e);
        res.status(500).json({ error: String(e) });
    }
});

app.listen(process.env.PORT || 3000, () => {
    console.log('DeepL proxy listening on port', process.env.PORT || 3000);
});
