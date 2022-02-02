const express = require("express");

const app = express();

app.get("/", (_, res) => {
    res.send("Hmmm, it seems you ventured into unknown territory :(");
});

app.listen(5000, (_) => {
    console.log("Started listening on port 5000");
});
  