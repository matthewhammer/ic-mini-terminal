#!/bin/bash
dfx -vv start --background &&\
dfx canister create textEdit &&\
dfx build textEdit &&\
dfx canister install textEdit &&\
dfx canister call windowSizeChange 'record {width=100; height=100; }' &&\
dfx canister call queryKeyDown 'vec { }' &&\
 #cargo run --release -- connect 127.0.0.1:8000 `dfx canister id textEdit`
echo Tests done. Success.

