// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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
        bool itIsOut;
    }

    struct Horse {
        uint256 code;
        string name;
        bool itIsOut;
    }

    struct Bet {
        Horse horse;
        address gambler;
        uint256 value;
    }

    Career[] public careers;
    Horse[] public horses;
    address public host;

    // Guardar el codigo de la carrera y devolver la posicion en la que quedó en la lista careers
    mapping(uint256 => uint256) public careerCodeToCareersListIndex;
    // Guardar el codigo del caballo y devolver la posicion en la que quedó en la lista horses
    mapping(uint256 => uint256) public horseCodeToHorsesListIndex;

    // Register a horse(Horse object) in a career(careerCode)
    mapping(uint256 => Career[]) public horseCodeToCareers;
    // Join a career(Career object) with a horse(horseCode) to find how many horses have a career
    mapping(uint256 => Horse[]) public careerCodeToHorses; // less than or equal to 5 horses per career

    // Register a bet per horse in a career and associate to gamber
    mapping(uint256 => Bet[]) public careerCodeToBet;

    bool internal careersListInitialized;
    bool internal horsesListInitialized;

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

        // Default values:
        // When an index doesn't exist into array then the return default value is 0
        // So if you save an object at position 0, it is imposible to differenciate between two values
        registerCareer(0, "defaultCareer");
        registerHorse(0, "defaultHorse");
        careersListInitialized = true;
        horsesListInitialized = true;
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
                itIsOut: false
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
                name: name,
                itIsOut: false
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
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[careerCode];
        
        // Validate career code to know if it doesn't exist already
        require(careerCodeListIndex > 0, "Career does not exists");

        Career memory careerNew = careers[careerCodeListIndex];
        
        // Validate if the career has CREATED state
        require(careerNew.state == CareerState.CREATED, "Career must have a CREATED state");
        
        // Get all careers per horse
        Career[] storage careersPerHorse = horseCodeToCareers[horseCode];
        
        // Validate if the career has a number less than 5 horses
        require(careersPerHorse.length < 5, "Career accepts 5 horses only");
        
        // Find Horse object
        uint256 horseCodeListIndex = horseCodeToHorsesListIndex[horseCode];
        
        // Validate horse code to know if it doesn't exist already
        require(horseCodeListIndex > 0, "Horse does not exists");
        
        Horse memory horseNew = horses[horseCodeListIndex];

        // Get all horses per career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];

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
        // TODO: Validate host user is the caller to the function
        // Find Career object
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[careerCode];
        
        // Validate career code to know if it doesn't exist already
        require(careerCodeListIndex > 0, "Career does not exists");

        Career storage careerObj = careers[careerCodeListIndex];

        // Get all horses per career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];
        
        // Validate if the career have and correct state and meet requirements to change state
        if (careerObj.state == CareerState.CREATED) {
            bool moreThan2Horses = horsesPerCareer.length >= 2;
            require(moreThan2Horses, "To change the state of the career then the career must have more than 2 horses registered");
            careerObj.state = CareerState.REGISTERED;
        } else {
            if (careerObj.state == CareerState.REGISTERED) {
                // TODO: finish the career and give the prize to the winners
                //careerObj.state = CareerState.FINISHED;
                
                // temporal sentence to get all money and send to the caller
                selfdestruct(payable(msg.sender));
            }
        }

        return careerObj.state;
    }

    /**
     * @dev bet in a unique horse per career an amount of Eth. The method is only used by non-host user
     * @param horseCode value of code horse
     * @param careerCode value of code career
     */
    function bet(uint256 horseCode, uint256 careerCode) public payable isGambler {
        // TODO: Validate if value of the ber is greater than or equal 1
        // Find Career object
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[careerCode];
        
        // Validate career code to know if it doesn't exist already
        require(careerCodeListIndex > 0, "Career does not exists");

        Career memory careerObj = careers[careerCodeListIndex];
        
        // Validate if the career has CREATED state
        require(careerObj.state == CareerState.REGISTERED, "Career must have a REGISTERED state");
        
        // Find Horse object
        uint256 horseCodeListIndex = horseCodeToHorsesListIndex[horseCode];
        
        // Validate horse code to know if it doesn't exist already
        require(horseCodeListIndex > 0, "Horse does not exists");

        Horse memory horseObj = horses[horseCodeListIndex];

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

        // Add bet in career
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
                    value: msg.value
                })
            );
        }

    }

}