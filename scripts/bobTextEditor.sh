#!/bin/bash
VERSION=`cat .DFX_VERSION`
export PATH=~/.cache/dfinity/versions/$VERSION:`pwd`:$PATH
echo "Attaching Bob to Alice\'s (already deployed) text editor."
cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit` --init '("Bob", (200, 100, 255))'

