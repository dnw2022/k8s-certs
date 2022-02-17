const express = require("express");

const app = express();

app.get("/example", (_, res) => {
    res.send("Looking good. This is an example response :)");
});

app.get("*", (req, res) => {
    res.send(`Hmmm, it seems you ventured into unknown territory :(. Request: ${req.originalUrl}`);
});

app.listen(5002, (_) => {
    console.log("Started listening on port 5002");
});
  