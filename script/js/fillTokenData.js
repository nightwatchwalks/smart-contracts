import * as dotenv from "dotenv";
import { createPublicClient, createWalletClient, http, parseGwei } from "viem";
import { goerli, mainnet, sepolia } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import nightWatchContractAbi from "./NightWatch.abi.json" assert { type: "json" };
dotenv.config();
import fs from "fs";

const nightWatchContract = getEnv("NIGHT_WATCH_CONTRACT");
const customRpcUrl = http(getEnv("CUSTOM_NODE_URL"));
const transport = customRpcUrl;
const client = getClient();

const account = privateKeyToAccount(getEnv("DEPLOYER_PRIVATE_KEY"));

const walletClient = createWalletClient({
	account,
	chain: getChain(),
	transport,
});

async function fillTokenData() {
	const initialNonce = await client.getTransactionCount({
		address: account.address,
	});
	for (let i = 0; i < 10; i++) {
		const { request } = await client.simulateContract({
			address: nightWatchContract,
			abi: nightWatchContractAbi,
			functionName: "fillTokenData",
			args: [
				JSON.parse(
					fs.readFileSync(
						`../../test/data/production/tokenData_${i + 1}.json`,
						"utf8"
					)
				),
			],
			account,
			nonce: initialNonce + i,
			gas: 5_000_000n,
			maxFeePerGas: parseGwei("11"),
			maxPriorityFeePerGas: parseGwei("1"),
		});
		const hash = await walletClient.writeContract(request);
		console.log("Transaction hash:", hash);
		client.waitForTransactionReceipt({ hash }).then(() => {
			console.log("Transaction confirmed.", i + 1);
		});
	}
}

async function clearTokenData() {
	const { request } = await client.simulateContract({
		address: nightWatchContract,
		abi: nightWatchContractAbi,
		functionName: "clearTokenData",
		account,
	});
	const hash = await walletClient.writeContract(request);
	console.log("Transaction hash:", hash);
	await client.waitForTransactionReceipt({ hash });
	console.log("Transaction confirmed.");
}

// console.log("Clearing token data...");
// await clearTokenData();

console.log("Filling token data...");
await fillTokenData();

function getClient() {
	return createPublicClient({
		chain: getChain(),
		transport: transport,
	});
}

function getChain() {
	const anvilLocalhost = {
		id: 31337,
		name: "Localhost",
		network: "localhost",
		nativeCurrency: {
			decimals: 18,
			name: "Ether",
			symbol: "ETH",
		},
		rpcUrls: {
			default: {
				http: ["http://127.0.0.1:8545"],
			},
			public: {
				http: ["http://127.0.0.1:8545"],
			},
		},
	};

	const chainId = Number(getEnv("CHAIN_ID"));

	return chainId === 31337
		? anvilLocalhost
		: chainId === 5
		? goerli
		: chainId === 11155111
		? sepolia
		: mainnet;
}

function getEnv(key) {
	const value = process.env[key];
	if (!value) {
		throw new Error(`Environment variable ${key} not set.`);
	}
	return value;
}
