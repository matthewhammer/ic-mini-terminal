
#!/bin/bash
VERSION=`cat .DFX_VERSION`
export PATH=~/.cache/dfinity/versions/$VERSION:`pwd`:$PATH
echo "Bob connects to Alice's text editor canister"
cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit` --user '("Bob", (200, 100, 255))'
