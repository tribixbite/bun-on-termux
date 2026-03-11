const fs = require("fs");
const os = require("os");
const path = require("path");
const tmpDir = os.tmpdir();
const w = fs.watch(tmpDir, () => {});
setTimeout(() => { w.close(); console.log("watch:ok"); }, 200);
