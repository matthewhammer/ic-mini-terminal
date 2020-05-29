# Use this in place of `dfx build` if you have issues with dfx+vessel
moc `./vessel sources` -c test/Main.mo && \
    cp Main.wasm canisters/test/Main.wasm
