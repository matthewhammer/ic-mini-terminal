# Use this in place of `dfx build` if you have issues with dfx+vessel
moc `./vessel sources` -c test/Counter.mo && \
    mv Counter.wasm canisters/test/Counter.wasm && \
moc `./vessel sources` -c test/Window.mo && \
    mv Window.wasm canisters/test/Window.wasm && \
moc `./vessel sources` -c test/Grid.mo && \
    mv Grid.wasm canisters/test/Grid.wasm && \
moc `./vessel sources` -c examples/mazeGame/Main.mo && \
    cp Main.wasm canisters/mazeGame/Main.wasm
