# Night Watch

Night Watch is an experimental, unique, and deflationary art collection with an on-chain game. Made by [Kaybid](https://twitter.com/KaybidSteps) and [Yigit Duman](https://twitter.com/YigitDuman).

## Background

#### **455 Unique Animations**

Each animation is hand-made and includes 15 frames.

(15 frames, 3 animals) = 455

#### **6825 Frames, 6825 Tokens**

Each frame is a one-of-a-kind digital asset / NFT!

(455 animations x 15 frames) = 6825

#### **Decreasing Supply**

The total supply decreases from 6825 as frames are merged. It can go as low as to 455!

#### **Weekly Auctions**

10% of the supply reserved to be auctioned every week with a starting price of 0.

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

<!-- | Contract              | Mainnet                                                                                                                 | Goerli                                                                                                                         |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `NightWatch`          | [`0x60bb1e2aa1c9acafb4d34f71585d7e959f387769`](https://etherscan.io/address/0x60bb1e2aa1c9acafb4d34f71585d7e959f387769) | [`0x60bb1e2aa1c9acafb4d34f71585d7e959f387769`](https://goerli.etherscan.io/address/0x60bb1e2aa1c9acafb4d34f71585d7e959f387769) |
| `NightWatchAuctioner` | [`0x600df00d3e42f885249902606383ecdcb65f2e02`](https://etherscan.io/address/0x600df00d3e42f885249902606383ecdcb65f2e02) | [`0x600df00d3e42f885249902606383ecdcb65f2e02`](https://goerli.etherscan.io/address/0x600df00d3e42f885249902606383ecdcb65f2e02) |
| `NightWatchMetadata`  | [`0x600000000a36f3cd48407e35eb7c5c910dc1f7a8`](https://etherscan.io/address/0x600000000a36f3cd48407e35eb7c5c910dc1f7a8) | [`0x600000000a36f3cd48407e35eb7c5c910dc1f7a8`](https://goerli.etherscan.io/address/0x600000000a36f3cd48407e35eb7c5c910dc1f7a8) |
| `NightWatchVRF`       | [`0x600000000a36f3cd48407e35eb7c5c910dc1f7a8`](https://etherscan.io/address/0x600000000a36f3cd48407e35eb7c5c910dc1f7a8) | [`0x600000000a36f3cd48407e35eb7c5c910dc1f7a8`](https://goerli.etherscan.io/address/0x600000000a36f3cd48407e35eb7c5c910dc1f7a8) | -->

## Usage

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

To build the contracts:

```sh
git clone https://github.com/uniodex/night-watch.git
cd night-watch
forge install
```

### Run Tests

In order to run unit tests, run:

```sh
forge test
```

### Run Slither

After [installing Slither](https://github.com/crytic/slither#how-to-install), run:

```sh
slither src/ --solc-remaps 'forge-std/=lib/forge-std/src/ solmate/=lib/solmate/src/ erc721a/=lib/erc721a/contracts/ chainlink/=lib/chainlink-brownie-contracts/contracts/src/ openzeppelin-erc721/=lib/openzeppelin-contracts/contracts/token/ERC721/ solady/=lib/solady/src/ solarray/=lib/solarray/src/' --filter-paths 'lib'
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

forge script script/deploy/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $API_KEY
```

### Other Scripts

Check the /script and /js-scripts folders to see helpful scripts for testing and post-deployment phase of Night Watch.

## Special Thanks

We're grateful to the open source community and awesome developers of Web3 for their contributions that made Night Watch possible. Thank you!

- transmissions11 and contributors of Solmate
- Vectorized and contributors of Solady
- Art Gobblers Team for their open source smart contracts
- Foundry creators and contributors
- Chiru Labs and contributors of ERC721A

## License

[MIT](LICENSE) © 2023 Night Watch

(License is for smart contracts. Visual artworks aren't included.)
