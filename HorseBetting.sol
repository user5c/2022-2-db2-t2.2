// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract HorseBetting {

    enum CareerState { CREATED, REGISTERED, FINISHED}    


    struct Career {
        uint256 code;
        string name;
        CareerState state;
    }

    struct Horse {
        uint256 code;
        string name;
    }

    struct HorseRace {
        Career carrer;
        Horse horse;
    }

    Career[] public careers;
    Horse[] public horses;

    // Guardar el codigo de la carrera y devolver la posicion en la que quedó en la lista careers
    mapping(uint256 => uint256) public careerCodeToCareersListIndex;
    // Guardar el codigo del caballo y devolver la posicion en la que quedó en la lista horses
    mapping(uint256 => uint256) public horseCodeToHorsesListIndex;

    // Register a horse(Horse object) in a career(careerCode)
    mapping(uint256 => Career[]) public horseCodeToCareers;
    // Join a career(Career object) with a horse(horseCode) to find how many horses have a career
    mapping(uint256 => Horse[]) public careerCodeToHorses;

    
    constructor() {
        //console.log("Owner contract deployed by:", msg.sender);
        //owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        //emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Create a Career Object and save identifier into a map careerCodeToCareersListIndex
     * @param code value to career
     * @param name value to career
     */
    function registerCareer(uint256 code, string memory name) public  {
        // TODO: Validate career code to know if it doesn't exist already
        careerCodeToCareersListIndex[code] = careers.length;
        careers.push(
            Career({
                code: code,
                name: name,
                state: CareerState.CREATED
            })
        );
    }

    /**
     * @dev Create a Horse Object and save identifier into a map horseCodeToHorsesListIndex
     * @param code value to career
     * @param name value to career
     */
    function registerHorse(uint256 code, string memory name) public  {
        // TODO: Validate horse code to know if it doesn't exist already
        horseCodeToHorsesListIndex[code] = horses.length;
        horses.push(
            Horse({
                code: code,
                name: name
            })
        );
    }

    /**
     * @dev Register a Horse in a Career wiht CREATED status
     * @param horseCode value of code horse
     * @param careerCode value of code career
     */
    function registerHorseInCareer(uint256 horseCode, uint256 careerCode) public  {
        // TODO: Validate horse code to know if it doesn't exist already
        // Find Career object
        uint256 careerCodeListIndex = careerCodeToCareersListIndex[careerCode];
        Career storage careerObj = careers[careerCodeListIndex];
        
        // Find Horse object
        uint256 horseCodeListIndex = horseCodeToHorsesListIndex[horseCode];
        Horse storage horseObj = horses[horseCodeListIndex];

        // TODO: Validate if the career has a number greater than 5 and less than 2 horses
        // TODO: Validate if the career has CREATED status

        // Add a career to the horse
        Career[] storage careersPerHorse = horseCodeToCareers[horseCode];
        careersPerHorse.push(careerObj);

        // Add a horse to the career
        Horse[] storage horsesPerCareer = careerCodeToHorses[careerCode];
        horsesPerCareer.push(horseObj);

    }

}