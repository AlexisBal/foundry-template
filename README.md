# Foundry Template

## 

## Requirements
Please install the following:
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Know the running version : ```git --version```
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
  - Know the running version : ```forge --version```
  - Download **foundryup** : ```curl -L https://foundry.paradigm.xyz | bash```
  - Install the last version of **forge**, **cast** and **anvil** : ```foundryup```

## Quickstart
```shell
git clone https://github.com/AlexisBal/foundry-template
cd foundry-template
```

## Commands 
- Run solidity compiler : ```forge build```
- Run tests : ```forge test```
- Run an anvil node : ```anvil```
- Run an anvil node and fork a network : ```anvil --fork-url <YOUR_RPC_URL>```
- Run tests with the anvil node : ```forge test --rpc-url http://127.0.0.1:8545```
- Run a test and debug it : ```forge test --debug <YOUR_TEST_NAME_FUNCTION>```

## Security 
Run a Slither security test
```shell
pip3 install slither-analyzer
pip3 install solc-select
solc-select install <YOUR_SOLIDITY_VERSION>
solc-select use <YOUR_SOLIDITY_VERSION>
slither src/<YOUR_.SOL_FILE>
```

## Resources
- [Foundry Official Documentation](https://book.getfoundry.sh/getting-started/first-steps)
- [Foundry template by Chainlink](https://github.com/smartcontractkit/foundry-starter-kit)




