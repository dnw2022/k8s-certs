const express = require("express");

const app = express();

app.get("/", (_, res) => {
    res.send("Hmmm, it seems you ventured into unknown territory :(");
});

app.get("/example", (_, res) => {
    res.send("Looking good. This is an example response :)");
});

app.listen(5002, (_) => {
    console.log("Started listening on port 5002");
});
  