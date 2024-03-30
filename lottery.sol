// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract lottery is CommitReveal {
    uint private N = 0;
    uint private T1 = 0;
    uint private T2 = 0;
    uint private T3 = 0;
    uint private numPlayer = 0;
    uint private timeStart = 0;
    mapping (address => uint) private player;
    mapping (uint => address) private noPlayer;
    mapping (address => uint) private playerETH;
    uint private reward = 0;
    address owner;

    constructor (uint _N,uint _T1,uint _T2,uint _T3) payable  {
        require(_N >= 2,"not enough player ");
        N = _N;
        T1 = _T1;
        T2 = _T2 + _T1;
        T3 = _T3 + _T2 + _T1;
        owner = msg.sender;
    }

    function stage1(uint transaction,uint salt) public payable{ 
        if(timeStart == 0){
            timeStart = block.timestamp;
        }
        require(block.timestamp - timeStart <= T1,"time");
        require(msg.value == 0.001 ether,"lol");
        reward += msg.value;
        player[msg.sender] = 0;
        commit(getSaltedHash(bytes32(transaction),bytes32(salt)));
        playerETH[msg.sender] = 0;
    }

    function stage2(uint transaction,uint salt) public {
        require(T1 <= block.timestamp - timeStart && block.timestamp - timeStart <= T2,"");
        revealAnswer(bytes32(transaction), bytes32(salt));
        player[msg.sender] = transaction;
        if(player[msg.sender] >=0 && player[msg.sender] <= 999){
            noPlayer[numPlayer] = msg.sender;
            playerETH[msg.sender] = 1000;
            numPlayer++;
        }
    }

    function stage3() public payable  {
        require(block.timestamp - timeStart >= T2 && block.timestamp - timeStart <= T3);
        address payable contractOwner = payable (owner);
        if(numPlayer == 0){
            contractOwner.transfer(reward);
        }else{
            uint winner = player[noPlayer[0]];
            for (uint i=1; i<numPlayer ; i++){
                winner = winner ^ player[noPlayer[i]];
            }
            winner = winner % numPlayer;
            address payable account = payable (noPlayer[winner]);
            account.transfer((reward *98)/100);
            contractOwner.transfer((reward *2)/100);
        }
    }

    function stage4() public payable {
        require(block.timestamp - timeStart > T3);
        require(playerETH[msg.sender] == 1000);
        address payable account = payable (msg.sender);
        account.transfer(0.001 ether);
        playerETH[msg.sender] = 0;
    }

    function reset_game() public payable {
        require(block.timestamp - timeStart > T3);
        require(owner == msg.sender);
        numPlayer = 0;
        timeStart = 0;
        address payable contractOwner = payable (owner);
        contractOwner.transfer(reward);
        reward = 0;
    }

}
