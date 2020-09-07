echo PATH = $PATH
echo vessel @ `which vessel`

echo
echo == Build.
echo

dfx start --background
dfx canister create --all
dfx build

echo
echo == Start service.
echo

dfx canister install --all

echo
echo == Test service.
echo

echo to do
# dfx canister call BigText selfTest
# LOOP="(true)";
# while [ "$LOOP" == "(true)" ]; do
#     LOOP=$(dfx canister call BigText doNextCall)
# done
