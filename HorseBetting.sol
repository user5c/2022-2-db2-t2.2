// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

/**
 * @title HorseBetting
 * @dev 
 */
contract HorseBetting {

    enum CareerState { CREATED, REGISTERED, FINISHED}    

    struct Career {
        uint256 code;
        string name;
        CareerState state;
        uint256 winningHorseCode;
    }

    struct Horse {
        uint256 code;
        string name;
    }

    struct Bet {
        Horse horse;
        address gambler;
        uint256 value;
        uint256 earnedValue;
    }

    Career[] public careers;
    Horse[] public horses;
    address public host;
    uint256 public lastWinningHorse;

    // TRANSLATE: Guardar el codigo de la carrera y devolver la posicion en la que quedó en la lista careers
    mapping(uint256 => uint256) public careerCodeToCareersListIndex;
    // TRANSLATE: Guardar el codigo del caballo y devolver la posicion en la que quedó en la lista horses
    mapping(uint256 => uint256) public horseCodeToHorsesListIndex;

    // Register a horse(Horse object) in a career(careerCode)
    mapping(uint256 => Career[]) public horseCodeToCareers;
    // Join a career(Career object) with a horse(horseCode) to find how many horses have a career
    mapping(uint256 => Horse[]) public careerCodeToHorses; // less than or equal to 5 horses per career

    // Register a bet per horse in a career and associate to gambler
    mapping(uint256 => Bet[]) public careerCodeToBet;

    bool private careersListInitialized;
    bool private horsesListInitialized;
    uint256 private seed;

    modifier isHost() {
        require(msg.sender == host, "Caller is not host");
        _;
    }

    modifier isGambler() {
        require(msg.sender != host, "Caller is not gambler");
        _;
    }

    constructor() {
        host = msg.sender;
        // Seed to make a random number
        seed = (block.timestamp + block.difficulty) % 100000000;

        // Default values:
        // When an index doesn't exist into array then the return default value is 0
        // So if you save an object at position 0, it is imposible to differenciate between two values
        registerCareer(0, "defaultCareer");
        registerHorse(0, "defaultHorse");
        careersListInitialized = true;
        horsesListInitialized = true;
    }

    function getRandomNumber(uint256 horsesPerCareerSize) private returns (uint256) {
        seed = (seed + block.timestamp + block.difficulty) % horsesPerCareerSize;
        return seed;
    }

    function getCareerStateString(CareerState state) private pure returns (string memory) {
        if (state == CareerState.CREATED) {
            return "Creada";
        } else if (state == CareerState.REGISTERED) {
            return "Registrada";
        } else {
            return "Terminada";
        }
    }

    function getCareerObj(uint256 careerCode) private view returns (Career storage) {
        // Find Career object
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[careerCode];
        
        // Validate career code to know if it doesn't exist already
        require(careerCodeListIndex > 0, "Career does not exists");

        return careers[careerCodeListIndex];
    }

    function getHorseObj(uint256 horseCode) private view returns (Horse storage) {
        // Find Horse object
        uint256 horseCodeListIndex = horseCodeToHorsesListIndex[horseCode];
        
        // Validate horse code to know if it doesn't exist already
        require(horseCodeListIndex > 0, "Horse does not exists");
        
        return  horses[horseCodeListIndex];
    }

    /**
     * @dev Create a Career Object and save identifier into a map careerCodeToCareersListIndex
     * @param code value to career
     * @param name value to career
     */
    function registerCareer(uint256 code, string memory name) public  isHost {
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[code];
        
        // Validate career code to know if it doesn't exist already 
        require(!careersListInitialized || careerCodeListIndex == 0, "The career code already exists");
        
        careerCodeToCareersListIndex[code] = careers.length;
        careers.push(
            Career({
                code: code,
                name: name,
                state: CareerState.CREATED,
                winningHorseCode: 0 // default value to defaultHorseCode
            })
        );
    }

    /**
     * @dev Create a Horse Object and save identifier into a map horseCodeToHorsesListIndex
     * @param code value to hourse
     * @param name value to hourse
     */
    function registerHorse(uint256 code, string memory name) public isHost {
        uint256 horseCodeListIndex = horseCodeToHorsesListIndex[code];
        
        // Validate horse code to know if it doesn't exist already
        require(!horsesListInitialized || horseCodeListIndex == 0, "The hourse code already exists");

        horseCodeToHorsesListIndex[code] = horses.length;
        horses.push(
            Horse({
                code: code,
                name: name
            })
        );
    }

    /**
     * @dev Register a Horse in a Career wiht CREATED state
     * @param horseCode value of code horse
     * @param careerCode value of code career
     */
    function registerHorseInCareer(uint256 horseCode, uint256 careerCode) public isHost {
        // Find Career object
        Career memory careerNew = getCareerObj(careerCode);
        
        // Validate if the career has CREATED state
        require(careerNew.state == CareerState.CREATED, "Career must have a CREATED state");
        
        // Get all careers per horse
        Career[] storage careersPerHorse = horseCodeToCareers[horseCode];
        
        // Find Horse object
        Horse memory horseNew = getHorseObj(horseCode);

        // Get all horses per career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];

        // Validate if the career has a number less than 5 horses
        require(horsesPerCareer.length < 5, "Career accepts 5 horses only");

        // Validate if the horse is already registered in the career
        for(uint8 i=0; i < horsesPerCareer.length; i++) {
            Horse memory horseInCareer = horsesPerCareer[i];
            require(horseInCareer.code != horseNew.code, "Horse is already registered in the career");
        }

        // Add a career to the horse
        careersPerHorse.push(careerNew);
        // Add a horse to the career
        horsesPerCareer.push(horseNew);

    }

    /**
     * @dev Change career state only if the career have greater than 2 horses registered
     * @param careerCode value of code career
     */
    function changeCareerState(uint256 careerCode) public isHost returns (CareerState){
        // Find Career object
        Career storage careerObj = getCareerObj(careerCode);

        // Get all horses per career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];
        
        // Validate if the career have and correct state and meet requirements to change state
        if (careerObj.state == CareerState.CREATED) {
            bool moreThan2Horses = horsesPerCareer.length >= 2;
            require(moreThan2Horses, "To change the state of the career then the career must have more than 2 horses registered");
            careerObj.state = CareerState.REGISTERED;
        } else if (careerObj.state == CareerState.REGISTERED) {
            // finish the career and give the prize to the winners

            // get winning horse
            uint256 horsesPerCareerSize = horsesPerCareer.length;
            uint256 winningHorseIndex = getRandomNumber(horsesPerCareerSize);
            Horse memory winningHorseObj = horsesPerCareer[winningHorseIndex];
            careerObj.winningHorseCode = winningHorseObj.code; // Save winning horse code into the CareerObj

            // Get all bets per career and add total bets
            // NOTE: The sum can be done when inserting the bets 
            Bet[] storage bets = careerCodeToBet[careerObj.code];
            uint256 sumTotalBets = 0;
            uint256 sumWinningBets = 0;
            for (uint256 i = 0; i < bets.length; i++) {
                sumTotalBets += bets[i].value;
                // TRANSLATE: Suma total de apuestas ganadoras
                if (winningHorseObj.code == bets[i].horse.code) {
                    sumWinningBets += bets[i].value;
                }
            }

            // transfer to the host
            uint256 toHost = sumTotalBets / 4;
            payable(host).transfer(toHost);


            // transfer to gamblers
            uint256 toGamblers = sumTotalBets - toHost;
            uint256 distributed = 0;
            for (uint256 j = 0; j < bets.length; j++) {
                Bet storage temporalBet = bets[j];
                if (winningHorseObj.code == temporalBet.horse.code) {
                    uint256 percentageBet = (temporalBet.value / sumWinningBets) * 1000; // Get percentage

                    // TRANSLATE: Repartir proporcionalmente la apuesta de acuerdo al monto que aposto
                    uint256 earnedValue = (percentageBet * toGamblers ) / 1000;

                    // Transfer to gambler
                    payable(temporalBet.gambler).transfer(earnedValue);
                    temporalBet.earnedValue = earnedValue;

                    distributed += earnedValue;
                }
            }
            
            uint256 remaining = toGamblers - distributed;
            payable(host).transfer(remaining);


            careerObj.state = CareerState.FINISHED;
            
            // temporal sentence to get all money and send to the caller
            //selfdestruct(payable(msg.sender));
            
        }

        return careerObj.state;
    }

    /**
     * @dev bet in a unique horse per career an amount of Eth. The method is only used by non-host user
     * @param horseCode value of code horse
     * @param careerCode value of code career
     */
    function bet(uint256 horseCode, uint256 careerCode) public payable isGambler {
        // TODO: Validate if value of the bet is greater than or equal 1
        // Find Career object
        Career memory careerObj = getCareerObj(careerCode);
        
        // Validate if the career has CREATED state
        require(careerObj.state == CareerState.REGISTERED, "Career must have a REGISTERED state");
        
        // Find Horse object
        Horse memory horseObj = getHorseObj(horseCode);

        // Get all horses per career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];

        // Validate if the horse is not already registered in the career
        bool horseRegistered = false;
        for (uint8 i=0; i < horsesPerCareer.length; i++) {
            Horse memory horseInCareer = horsesPerCareer[i];
            if (horseInCareer.code == horseObj.code) {
                horseRegistered = true;
                break;
            }
        }
        require(horseRegistered, "Horse is not already registered in the career");

        // Get all bets per career
        Bet[] storage bets = careerCodeToBet[careerObj.code];

        // Validate if the gambler is already in the career and if he want increase the bet
        bool gamblerInCareer = false;
        Bet memory betObjTmp;
        uint256 indexBet = 0;
        for (indexBet; indexBet < bets.length; indexBet++) {
            betObjTmp = bets[indexBet];
            if (betObjTmp.gambler == msg.sender) {
                gamblerInCareer = true;
                break;
            }
        }
        
        // Add bet in career
        if (gamblerInCareer) {
            require (betObjTmp.horse.code == horseObj.code, "The user has already registered a bet in other horse on this career");
            // Increase the bet 
            betObjTmp.value += msg.value;
            bets[indexBet] = betObjTmp;
        } else {
            bets.push(
                Bet({
                    horse: horseObj,
                    gambler: msg.sender,
                    value: msg.value,
                    earnedValue: 0
                })
            );
        }

    }

    function getCareersInfo() public view  {
        uint256 total = careers.length - 1; // Drop defaultCareer (-1)
        console.log("Carreras Totales: ", total);

        for (uint256 i = 1; i < careers.length; i++) {
            Career memory careerToLog = careers[i];
            console.log("#######       CARRERA      #######");
            console.log("Codigo: ", careerToLog.code);
            console.log("Nombre: ", careerToLog.name);
            console.log("Estado: ", getCareerStateString(careerToLog.state));
            console.log("-------CABALLOS EN CARRERA-------");
            
            // Get all horses per career
            Horse[] memory horsesPerCareer = careerCodeToHorses[careerToLog.code];
            for (uint256 j = 0; j < horsesPerCareer.length; j++) {
                Horse memory horseInCareer = horsesPerCareer[j];
                console.log("#", j + 1);
                console.log("Codigo: ", horseInCareer.code);
                console.log("Nombre: ", horseInCareer.name);
            }
            console.log(">>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<");
        }
    }

    function getWinningCareerInfo(uint256 careerCode) public view {
        // Find Career object
        Career memory careerObj = getCareerObj(careerCode);
        // TODO: Validate 10 winningHorseCode like defect value
        Horse memory winningHorseObj = getHorseObj(careerObj.winningHorseCode);

        console.log("#######       CARRERA      #######");
        console.log("Codigo: ", careerObj.code);
        console.log("Nombre: ", careerObj.name);
        console.log("Estado: ", getCareerStateString(careerObj.state));
        console.log("----------CABALLO GANADOR----------");
        console.log("Codigo: ", winningHorseObj.code);
        console.log("Nombre: ", winningHorseObj.name);
        console.log("-------------GANADORES-------------");

        // Get all bets per career and add total bets
        Bet[] memory bets = careerCodeToBet[careerObj.code];
        for (uint256 i = 0; i < bets.length; i++) {
            Bet memory temporalBet = bets[i];
            if (winningHorseObj.code == temporalBet.horse.code) {
                console.log(temporalBet.gambler, temporalBet.earnedValue);
            }
        }
    }


}