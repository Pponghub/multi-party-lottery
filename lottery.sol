// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./CommitReveal.sol";

contract RWAPSSF is CommitReveal {
    struct Player {
        uint choice; // 0 - Rock, 1 - Fire , 2 - Scissors , 3 - Sponge , 4 - Paper , 5 - Air , 6 - Water , 7 - undefined
        address addr;
        uint time;
    }
    uint public numPlayer = 0;
    uint public numReveal = 0;
    uint public numCommit = 0;
    uint public commitTimeP0;
    uint public commitTimeP1;
    uint public revealTimeP0;
    uint public revealTimeP1;
    uint public reward = 0;
    mapping (uint => Player) public player;
    uint public numInput = 0;

    function addPlayer() public payable {
        require(numPlayer < 2);
        require(msg.value == 1 ether);
        reward += msg.value;
        player[numPlayer].addr = msg.sender;
        player[numPlayer].choice = 7;
        player[numPlayer].time = block.timestamp;
        numPlayer++;
    }

    function input(uint choice,uint salt) public  {
        require(numPlayer == 2);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4 || choice == 5 || choice == 6);
        if(msg.sender == player[0].addr){
            player[0].choice = choice;
            commit(getSaltedHash(bytes32(choice),bytes32(salt)));
            commitTimeP0 = block.timestamp;
        }else{
            player[1].choice = choice;
            commit(getSaltedHash(bytes32(choice),bytes32(salt)));
            commitTimeP1 = block.timestamp;
        }
        numCommit++;
    }

    function withdraw() public {
        uint idx;
        if(msg.sender == player[0].addr){
            idx = 0;
        }else{
            idx = 1;
        }
        address payable account = payable(player[idx].addr);
        if(numPlayer == 1 ){
            require((block.timestamp - player[idx].time) > 600 ,"not enough time 1");
            account.transfer(reward);
        }else if(numPlayer == 2 && numCommit==1){
            if(idx == 0){
                require((block.timestamp - commitTimeP0) > 300,"not enough time 2 ");
            }else{
                require((block.timestamp - commitTimeP1) > 300,"not enough time 3 ");
            }
            account.transfer(reward);
        }else if(numPlayer == 2 && numReveal==1){
            if(idx == 0){
                require((block.timestamp - revealTimeP0) > 300,"not enough time 4 ");
            }else{
                require((block.timestamp - revealTimeP1) > 300,"not enough time 5 ");
            }
            account.transfer(reward);
        }
        _reset();
    }

    function revealPlayer(uint choice,uint salt) public {
        uint idx;
        if(msg.sender == player[0].addr){
            idx = 0;
        }else{
            idx = 1;
        }
        require(numPlayer == 2);
        require(numCommit == 2);
        require(msg.sender == player[idx].addr);
        require(choice == 0 || choice == 1 || choice == 2 || choice == 3 || choice == 4 || choice == 5 || choice == 6);
        revealAnswer(bytes32(choice), bytes32(salt));
        numReveal++;
        if(idx==0){
            revealTimeP0 = block.timestamp;
        }else{
            revealTimeP1 = block.timestamp;
        }

        if (numReveal == 2) {
            _checkWinnerAndPay();
        }
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player[0].choice;
        uint p1Choice = player[1].choice;
        address payable account0 = payable(player[0].addr);
        address payable account1 = payable(player[1].addr);
        if ((p0Choice + 1) % 7 == p1Choice || (p0Choice + 2) % 7 == p1Choice || (p0Choice + 3) % 7 == p1Choice ) {
            // to pay player[0]
            account0.transfer(reward);
        }
        else if ((p1Choice + 1) % 7 == p0Choice || (p1Choice + 2) % 7 == p0Choice || (p1Choice + 3) % 7 == p0Choice) {
            // to pay player[1]
            account1.transfer(reward);    
        }
        else {
            // to split reward
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        _reset();
    }

    function _reset() private {
        numPlayer = 0;
        numReveal = 0;
        numCommit = 0;
        commitTimeP0 = 0;
        commitTimeP1 = 0;
        revealTimeP0 = 0;
        revealTimeP1 = 0;
        reward = 0;
        numInput = 0;
        delete player[0];
        delete player[1];
    }
}
