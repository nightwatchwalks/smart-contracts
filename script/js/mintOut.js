import * as dotenv from "dotenv";
import { createPublicClient, createWalletClient, http, parseGwei } from "viem";
import { goerli, mainnet } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import nightWatchContractAbi from "./NightWatch.abi.json" assert { type: "json" };
dotenv.config();

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

async function mintRemainingSupplyToVault() {
	const { request } = await client.simulateContract({
		address: nightWatchContract,
		abi: nightWatchContractAbi,
		functionName: "mintRemainingSupplyToVault",
		account,
		maxFeePerGas: parseGwei("11"),
		maxPriorityFeePerGas: parseGwei("1"),
	});
	const hash = await walletClient.writeContract(request);
	console.log("Transaction hash:", hash);
	await client.waitForTransactionReceipt({ hash });
	console.log("Transaction confirmed.");
}

console.log("Minting remaining supply to vault...");
await mintRemainingSupplyToVault();

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

	return chainId === 31337 ? anvilLocalhost : chainId === 5 ? goerli : mainnet;
}

function getEnv(key) {
	const value = process.env[key];
	if (!value) {
		throw new Error(`Environment variable ${key} not set.`);
	}
	return value;
}
