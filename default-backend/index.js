const express = require("express");

const app = express();

app.get("/", (_, res) => {
    res.send("We will be back soon. Sorry about this :(");
});

app.listen(5000, (_) => {
    console.log("Started listening on port 5000");
});
  