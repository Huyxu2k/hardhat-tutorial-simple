import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Raffle is VRFConsumerBaseV2 {
    uint256 private immutable i_entrancefee;
    address payable[] public players;
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS=3;
    uint32 private constant NUM_WORDS=1;

    address private historyWinner;

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 value,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entrancefee = value;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId=subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
    }

    function enterRaffle() public payable {
        require(msg.value < i_entrancefee, "Not enough ETH");
        players.push(payable(msg.sender));

        //Emit an event
        emit RaffleEnter(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entrancefee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return players[index];
    }

    function requestRandomWinner() external {
        uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
       emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,// requestId
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner= randomWords[0] % players.length;
        address payable recentWinner=players[indexOfWinner];
        historyWinner=recentWinner;

        (bool success,) =recentWinner.call{value:address(this).balance}("");

        require(success,"Transfer is failed");

        emit WinnerPicked(recentWinner);
        
    }

    function getHistoryWinner() public view returns(address){
        return historyWinner;
    }
}
