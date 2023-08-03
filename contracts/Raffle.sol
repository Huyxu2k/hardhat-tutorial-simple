import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error Raffle_UpkeepNotNeeded(uint256 currentBalance,uint256 numPlayers,uint256 raffleState );

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    //enum 
    enum RaffleState{
        OPEN,        //=>0
        CACULATING   //=>1
    }

    //Variable immutable,constant
    uint256 private immutable i_entrancefee;
    address payable[] public s_players;
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
     uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS=3;
    uint32 private constant NUM_WORDS=1;

    address private s_historyWinner;
    RaffleState private s_raffleState;
    uint256 private s_lateTimeStamp;
   

    //event
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 value,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entrancefee = value;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId=subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
        s_raffleState=RaffleState.OPEN;
        s_lateTimeStamp=block.timestamp;
        i_interval=interval;
    }
    
    //function
    function enterRaffle() public payable {
        //check value 
        require(msg.value < i_entrancefee, "Not enough ETH");
        //check state
        require(s_raffleState!=RaffleState.OPEN,"Not Open");

        s_players.push(payable(msg.sender));
        //Emit an event
        emit RaffleEnter(msg.sender);
    }
    function performUpkeep(bytes calldata /*performData*/) external override{
        (bool upkeepNeeded,) =checkUpkeep("");
        if(!upkeepNeeded){
           revert Raffle_UpkeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        }
        s_raffleState=RaffleState.CACULATING;
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
        uint256 indexOfWinner= randomWords[0] % s_players.length;
        address payable recentWinner=s_players[indexOfWinner];
        s_historyWinner=recentWinner;

        //Reset
        s_raffleState=RaffleState.OPEN;
        s_players= new address payable[](0);
        s_lateTimeStamp=block.timestamp;
        (bool success,) =recentWinner.call{value:address(this).balance}("");

        require(success,"Transfer is failed");

        emit WinnerPicked(recentWinner);
        
    }

    function getHistoryWinner() public view returns(address){
        return s_historyWinner;
    }
    function checkUpkeep(bytes memory /*checkData*/) public override returns(bool upkeepNeeded,bytes memory /*performData*/){
        bool isOpen=(RaffleState.OPEN==s_raffleState);
        bool timePassed=((block.timestamp-s_lateTimeStamp)>i_interval);
        bool hasPlayers=(s_players.length>0);
        bool hasBalance=address(this).balance>0;
        upkeepNeeded=(isOpen && timePassed && hasPlayers && hasBalance);
    }

    //view,pure
    function getEntranceFee() public view returns (uint256) {
        return i_entrancefee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
    function getNumWords() public pure returns(uint256){
        return NUM_WORDS;
    }
    function getNumberOfPlayers() public view returns(uint256){
        return s_players.length;
    }
    function getLastestTimeStamp() public view returns(uint256){
        return s_lateTimeStamp;
    }
    function getRequestConfirmations() public pure returns(uint256){
        return REQUEST_CONFIRMATIONS;
    }
}
