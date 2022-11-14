// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import { IRandomGameDescriptor } from './interfaces/IRandomGameDescriptor.sol';

contract RandomGame is Ownable {
	event SetWinner(address indexed finalWinner1, address indexed finalWinner2, address indexed finalWinner3);

	using Counters for Counters.Counter;

	IRandomGameDescriptor public randomGameDescriptor;

	uint256 private constant GAMEENDTIME = 864000; // 10 days

	bool private gameStart; // game start true or false
	uint256 private gameStartTime = 0; // game start time based on block.timestamp

	uint256 private playerLimit;
	uint256 private playerCount;
	uint256 private price;

	Counters.Counter private tokenCount;

	address[] public winner1List;
	address[] public winner2List;
	address[] public winner3List;

	/***
	 * @notice constructor
	 * @param _randomGameDescriptor address for test descriptor
	 * @param _playerLimit limit of the player that allowed to join
	 * @param _price entry price
	 */
	constructor(address _randomGameDescriptor, uint256 _playerLimit, uint256 _price) {
		randomGameDescriptor = IRandomGameDescriptor(_randomGameDescriptor);

		playerLimit = _playerLimit;
		playerCount = 0;
		price = _price;
	}

	/**
	 * @notice get price
	 */
	function getPrice() public view returns (uint256) {
		return price;
	}

	/**
	 * @notice set price
	 * @param _price entry price
	 */
	function setPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	/**
	 * @notice get player limit
	 */
	function getPlayerLimit() public view returns (uint256) {
		return playerLimit;
	}

	/**
	 * @notice set player limit
	 * @param _playerLimit limit of the player that allowed to join
	 */
	function setPlayerLimit(uint256 _playerLimit) public onlyOwner {
		playerLimit = _playerLimit;
	}

	/**
	 * @notice get token start
	 */
	function getTokenStart() public view returns (uint256) {
		return randomGameDescriptor.getTokenStart();
	}

	/**
	 * @notice start new game
	 */
	function startGame() public onlyOwner {
		gameStart = true;
		gameStartTime = block.timestamp + GAMEENDTIME;

		playerCount = 0;
		randomGameDescriptor.setTokenStart(tokenCount.current());
	}

	/**
	 * @notice stop game
	 */
	function stopGame() public onlyOwner {
		gameStart = false;
	}

	/**
	 * @notice get player data
	 * @param _tokenId token id
	 */
	function getPlayerData(uint256 _tokenId) public view returns (address) {
		return randomGameDescriptor.getPlayerData(_tokenId);
	}

	/**
	 * @notice set the new descriptor
	 * @param _randomGameDescriptor address for test descriptor
	 */
	function setDescriptor(address _randomGameDescriptor) public onlyOwner {
		require(_randomGameDescriptor != address(0), 'INVALID_ADDRESS');
		randomGameDescriptor = IRandomGameDescriptor(_randomGameDescriptor);
	}

	/**
	 * @notice set the player data
	 * @param _referalAddress referal address
	 */
	function setPlayerData(address _referalAddress) public payable {
		require(gameStart == true, 'game is not started');
		require(gameStartTime >= block.timestamp, 'game expired');
		require(msg.value >= price, 'not enough coin');
		require(playerLimit >= playerCount, 'limit reach');

		address playerAddress = msg.sender;

		randomGameDescriptor.setPlayerData(tokenCount.current(), playerAddress, _referalAddress);

		playerCount = playerCount + 1;
		tokenCount.increment();
	}

	/**
	 * @notice set winner
	 */
	function setWinner() public onlyOwner returns (address, address, address) {
		stopGame();

		address finalWinner1;
		address finalWinner2;
		address finalWinner3;
		(finalWinner1, finalWinner2, finalWinner3) = randomGameDescriptor.setWinner(tokenCount.current());

		winner1List.push(finalWinner1);
		winner2List.push(finalWinner2);
		winner3List.push(finalWinner3);
		emit SetWinner(finalWinner1, finalWinner2, finalWinner3);
		return (finalWinner1, finalWinner2, finalWinner3);
	}
}
