# Night Watch

Night Watch is an art collection of 455 animated impossible animal trios strolling around in a mysterious void. Each animation has 15 frames, and each frame of each animation is an NFT. By collecting the same frames of an animation in the same wallet, you form an animation of those frames. Your goal is to complete the animation by collecting all 15 frames.

Made by [Kaybid](https://twitter.com/KaybidSteps) and [Yigit Duman](https://twitter.com/YigitDuman).

## Launch Roadmap

- Temporarily increase metadata server's and lambda function's default cache time to 30 minutes.
- Stop all servers and website APIs. Make sure to remove metadata server configuration.
- Remove all the generated images from S3 in case of testing leftovers. Create generated-gifs folder and make it public.
- Reset redis server
- Ensure deployment configuration is correct for deployment scripts.
- Deploy NightWatchPaymentDivider, NightWatchMetadata, NightWatch, contracts consecutively.
- Map gifs randomly using the contract deployment blockhash.
- Update AWS lambda function configuration.
- Update metadata-server configuration.
- Genereate the token data with nw-offchain-tools using the contract deployment blockhash as the random seed.
- Use `NightWatch.fillTokenData` in 10 batches to upload the data on-chain.
- Mint all tokens to the vault.
- Use nw-offchain-tools/generate-all-token-images
- Resume metadata server.
- Update metadata address.
- Use `NightWatch.setMergePaused(false)` to start merge events.
- Deploy NightWatchVendor
- Update configuration and run event-storage-server on nw-offchain-tools
- Update configuration on websites
- Approve NightWatchVendor for vault address.
- Reduce metadata server's and lambda function's default cache time to 60 seconds.
- Refresh metadata of all tokens
- Run sale-website.
- Add buy now button to the main website.
- Transfer all ownerships to Gnosis.
- After some time, when you are sure there are no problems with merge and token data, use `NightWatch.lockState` to lock changing states.

## Deployments

Not yet disclosed.

## Usage

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

To build the contracts:

```sh
git clone https://github.com/nightwatchwalks/smart-contracts.git
cd smart-contracts
forge install
```

### Run Tests

In order to run unit tests, run:

```sh
forge test
```

### Run Slither

After [installing Slither](https://github.com/crytic/slither#how-to-install), run in the main folder:

```sh
slither .
```

### Update Gas Snapshots

To update the gas snapshots, run:

```sh
forge snapshot
```

### Deploy Contracts

In order to deploy the Night Watch contracts, set the relevant constants in the `Deploy` script, and run the following command(s):

```sh
export PRIVATE_KEY=$PRIVATE_KEY

forge script script/DeployNightWatch.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $API_KEY
forge script script/DeployVendor.s.sol:DeployVendor --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $API_KEY
```

### Other Scripts

Check the /script and /script/js folders to see helpful scripts for testing and post-deployment phase of Night Watch.

## Special Thanks

We're grateful to the open source community and awesome developers of Web3 for their contributions that made Night Watch possible. Thank you!

- transmissions11 and contributors of Solmate
- Vectorized and contributors of Solady
- Paradigm for their open source smart contracts
- Foundry creators and contributors
- Chiru Labs and contributors of ERC721A

## License

[MIT](LICENSE) © 2023 Night Watch

(License is for smart contracts. Artworks, animations and visuals aren't included.)
