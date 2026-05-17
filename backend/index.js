const pg = require('pg');
const express = require('express');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const cors = require('cors');
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const app = express();
const port=3000;

const pool = new pg.Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: parseInt(process.env.DB_PORT),
    connectionTimeoutMillis: 5000
});

console.log("Connecting...:")

app.use(cors({
  origin: ['http://localhost:8080'],
  methods: ['GET', 'POST'],
  credentials: true
}));
app.use(bodyParser.json());
app.use(
    bodyParser.urlencoded({
        extended: true,
    })
)

async function authenticateUser(username, inputPassword) {
    try {
        const query = 'SELECT * FROM users WHERE user_name = $1';
        const result = await pool.query(query, [username]);
        if (result.rows.length === 0) {
            return { success: false, message: 'Gebruiker niet gevonden' };
        }
        const user = result.rows[0];
        let isValid = false;
        if (user.password && user.password.length === 60) {
            isValid = await bcrypt.compare(inputPassword, user.password);
        } else {
            isValid = inputPassword === user.password;
            if (isValid) {
                console.log(`🔄 Migrating password for user: ${username}`);
                const saltRounds = 10;
                const hashedPassword = await bcrypt.hash(inputPassword, saltRounds);
                const updateQuery = 'UPDATE users SET password = $1 WHERE user_name = $2';
                await pool.query(updateQuery, [hashedPassword, username]); 
                console.log(`✅ Password migrated for user: ${username}`);
            }
        }
        if (!isValid) {
            return { success: false, message: 'Ongeldige inloggegevens' };
        }
        return { success: true, user: { id: user.id, username: user.user_name } };
    } catch (error) {
        console.error('Database error:', error);
        throw error;
    }
}

app.get('/authenticate/:username/:password', async (request, response) => {
    const { username, password } = request.params;

    if (!username || !password) {
        return response.status(400).json({ error: 'Gebruikersnaam en wachtwoord zijn vereist' });
    }

    try {
        const result = await authenticateUser(username, password);
        
        if (result.success) {
            response.status(200).json(result);
        } else {
            response.status(401).json(result);
        }
    } catch (error) {
        console.error('Auth error:', error);
        response.status(500).json({ error: 'Interne serverfout' });
    }
});

app.listen(port, () => {
    console.log(`App running securely on port ${port}.`);
    console.log(`⚠️  WARNING: Ensure .env file is set and .gitignore includes it.`);
});
