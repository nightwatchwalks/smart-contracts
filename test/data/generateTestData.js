const fs = require("fs");

const translateTokenDataAsUint24Array = (tokenData) => {
	const uint24Array = [];

	for (const data of tokenData) {
		const set = data[0];
		const frame = data[1];

		// Convert set into binary number
		const setBinary = set.toString(2).padStart(9, "0");

		// Initialize frame binary array
		let frameBinary = "000000000000000";

		// Change (14 - frame)th character to 1 to add the frame into binary array
		frameBinary = `${frameBinary.substr(0, 14 - frame)}1${frameBinary.substr(
			14 - frame + 1
		)}`;

		// Combine the set and frame binary numbers
		const binary = setBinary + frameBinary;

		// Convert the binary number to a uint24
		const uint24 = parseInt(binary, 2);

		// Add the uint24 to the array
		uint24Array.push(uint24);
	}

	return uint24Array;
};

const tokenData = [];
for (let i = 1; i < 456; i++) {
	tokenData.push([i, 0]);
}

tokenData.push([0, 14]);

fs.writeFileSync(
	"tokenData_455.json",
	JSON.stringify(translateTokenDataAsUint24Array(tokenData))
);
