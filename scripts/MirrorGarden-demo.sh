#!/bin/bash
VERSION=`cat .DFX_VERSION`
export PATH=~/.cache/dfinity/versions/$VERSION:`pwd`:$PATH
echo
echo Starting: Mirror Garden demo...using DFINITY SDK replica
echo
dfx stop &&\
dfx start --background --clean &&\
dfx canister create MirrorGarden &&\
dfx build MirrorGarden &&\
dfx canister install MirrorGarden
echo
echo Mirror Garden canister:
echo   `dfx canister id MirrorGarden`
echo
echo Hint: Ready for manual mini-terminal connection:
echo   For example:
echo
echo   ic-mt connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("User", (100, 200, 200))'
echo
case ${1} in
  "" | "0")
    echo No initial terminals requested.  All done.
    ;;
  "1")
    ic-mt ${2} connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("Alice", (100, 200, 200))'
    echo
    echo Started one live terminal for Alice.
    echo
    ;;
  "2")
    ic-mt ${2} connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("Alice", (100, 200, 200))' &
    ic-mt ${2} connect 127.0.0.1:8000 `dfx canister id MirrorGarden` --user '("Bob", (200, 100, 200))' &
    echo
    echo Started two live terminals, for Alice and Bob.
    echo
    ;;
  *)
    echo Expected a number: 0, 1 or 2, but instead got '${1}'
    exit -1
esac
