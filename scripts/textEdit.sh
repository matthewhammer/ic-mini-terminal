#!/bin/bash
VERSION=`cat .DFX_VERSION`
export PATH=~/.cache/dfinity/versions/$VERSION:`pwd`:$PATH
dfx start --background --clean &&\
dfx canister create textEdit &&\
dfx build textEdit &&\
dfx canister install textEdit ||\
dfx canister install textEdit --mode=reinstall &&\
cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit`

