#!/bin/bash
VERSION=`cat .DFX_VERSION`
export PATH=~/.cache/dfinity/versions/$VERSION:`pwd`:$PATH
echo
echo Starting: Mirror Garden 2-user demo...using DFINITY SDK replica
echo
dfx stop &&\
dfx start --background --clean &&\
dfx canister create MirrorGarden &&\
dfx build MirrorGarden &&\
dfx canister install MirrorGarden

ic-mt connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("Alice", (100, 200, 200))' &
ic-mt connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("Bob", (200, 100, 200))' &
echo
echo Mirror Garden 2-user demo, started.
echo
