
const http = require("http");
const fs = require("fs");
const { Client } = require("pg");

const PORT = 3000;
const dbName = fs.readFileSync("/run/secrets/db_name", "utf8").trim();
const dbUser = fs.readFileSync("/run/secrets/db_user", "utf8").trim();
const dbPassword = fs.readFileSync("/run/secrets/db_password", "utf8").trim();
const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: dbName,
    user: dbUser,
    password: dbPassword,
});

async function startServer() {

    try {
        await client.connect();
        console.log("✅ Connected to PostgreSQL");
    } catch (err) {
        console.error("❌ Failed to connect to PostgreSQL");
        console.error(err.message);
        process.exit(1);
    }

    const server = http.createServer((req, res) => {
        if (req.method === "POST" && req.url === "/logs") {

    let body = "";

    req.on("data", chunk => {
        body += chunk;
    });

    req.on("end", async () => {

        console.log("=== POST /logs ===");
        console.log("Body brut:", body);

        try {

            const log = JSON.parse(body);

            console.log(log);

            const result = await client.query(
                "INSERT INTO logs(level, message) VALUES($1,$2) RETURNING *",
                [log.level, log.message]
            );

            console.log(result.rows);

            res.writeHead(201, {
                "Content-Type": "application/json"
            });

            res.end(JSON.stringify(result.rows[0]));

        } catch (err) {

            console.error(err);

            res.writeHead(500, {
                "Content-Type": "application/json"
            });

            res.end(JSON.stringify({
                error: err.message
            }));

        }

    });

    return;
}

        // ===========================
        // GET /logs
        // ===========================
        if (req.method === "GET" && req.url === "/logs") {

            (async () => {

                try {

                    const result = await client.query(
                        "SELECT * FROM logs ORDER BY id DESC"
                    );

                    res.writeHead(200, {
                        "Content-Type": "application/json"
                    });

                    res.end(JSON.stringify(result.rows));

                } catch (err) {

                    console.error(err);

                    res.writeHead(500, {
                        "Content-Type": "application/json"
                    });

                    res.end(JSON.stringify({
                        error: err.message
                    }));

                }

            })();

            return;
        }

        res.writeHead(404, {
            "Content-Type": "application/json"
        });

        res.end(JSON.stringify({
            message: "Route not found"
        }));

    });

    server.listen(PORT, () => {
        console.log(`🚀 Server listening on port ${PORT}`);
    });

}

startServer();