# multi-party-lottery
เกม lottery ที่สามารถเล่นได้หลายคนร่วมกัน 
- ผู้ deploy contract สามารถกำหนดเวลาในแต่ละขั้นตอน (เพิ่มผู้เล่น , reveal เลข lottery , มอบรางวัลให้ผู้ชนะ , ถอนเงินคืน) ได้
- ผู้เล่นจะต้องลงเงิน 0.001 ETH เพื่อเริ่มเล่นและใส่เลข lottery 0 - 999 มาหนึ่งเลข
- ในกรณีที่ผู้เล่นใส่เลข lottery เกิน 0 - 999 หรือไม่มา reveal เลข lottery ภายในเวลาที่กำหนด ผู้เล่นจะเสียเงินที่ลงไว้และถูกตัดออกจากการเล่น
- ผู้ชนะจะได้รางวัล 0.98 ส่วนจากเงินกองกลาง และผู้ deploy จะได้เงิน 0.2 จากเงินกองกลาง ในกรณีที่ผู้เล่นทำผิดกฏทั้งหมด เงินรางวัลจะตกเป็นของผู้ deploy คนเดียว

```
constructor (uint _N,uint _T1,uint _T2,uint _T3) payable  {
    require(_N >= 2,"not enough player ");
    N = _N;
    T1 = _T1;
    T2 = _T2 + _T1;
    T3 = _T3 + _T2 + _T1;
    owner = msg.sender;
}
```

เมื่อเริ่ม deploy contract เราจะเก็บ address ของผู้ deploy ไว้เพื่อแบ่งเงินรางวัลให้ในภายหลัง และตั้งเวลาของแต่ละ stage ไว้

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
stage1 จะให้ผู้เล่นลงเงินและเลข lottery โดยหลังจากผู้เล่นคนแแรกลงเล่นแล้ว ผู้เล่นคนอื่นจะต้องลงเล่นภายในเวลา T1 วินาที

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
stage2 จะให้ผู้เล่น reveal เลข lottery หากไม่ทำภายในเวลา T2 วินาที จะถูกริบเงินรางวัลไปและหมดสิทธิ์ในการเล่น โดยเช็คเวลาจาก block.timestamp - timestart ที่เก็บมาจาก stage1 เมื่อมีผู้เล่นคนแรกกดลงเล่น 
จะมีการเก็บเลข lottery ของผู้เล่นลงใน player คู้กับ address ของผู้เล่นคนนั้น และถ้าเลข lottery อยู่ตั้งแต่ 0 - 999 จะเพิ่ม address ของผู้เล่นคู่กับเลขไว้ใน noPlayer เพื่อแสดงว่าเป็นผู้เล่นที่ทำถูกตามกฏและเซ็ตให้ผู้เล่นคนนั้้นสามารถกดถอนเงินได้

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

stage3 จะให้ผู้ deploy contract กดจ่ายเงินให้กับผู้ชนะภายใน T3 วินาที โดยหาผู้เล่นจากการนำเลข lottery ของผู้เล่นที่อยู่ใน noPlayer มา XOR กัน และ mod ด้วยจำนวนผู้เล่นที่ไม่ทำผิดกฏ เพื่อหาเลขของผู้ชนะและจ่ายเงินให้ผู้ชนะ หากไม่มีผู้เล่นที่ทำตามกฏเลย เงินรางวัลจะเป็นของผู้ deploy contract 

    function stage4() public payable {
        require(block.timestamp - timeStart > T3);
        require(playerETH[msg.sender] == 1000);
        address payable account = payable (msg.sender);
        account.transfer(0.001 ether);
        playerETH[msg.sender] = 0;
    }

stage4 จะเกิดขึ้นในกรณีที่ผู้ deploy ไม่จ่ายเงินภายในเวลา T3 วินาที ผู้เล่นที่ลงเงินไว้และไม่ได้ทำผิดกฏอะไรจะสามารถกดดถอนเงินที่ลงไว้คืนได้โดยตรวจสอบจาก playerETH ถ้าหากมีค่า 1000 อยู่ จะกดได้ เมื่อกดแล้วจะเปลี่ยนค่านั้นเป็น 0 เพื่อป้องกันการกดซ้ำ
