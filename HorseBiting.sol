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

    mapping(uint256 => Horse[]) public careerCodeToHorses;
    mapping(uint256 => Career[]) public horseCodeToCareers;

    
    constructor() {
        //console.log("Owner contract deployed by:", msg.sender);
        //owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        //emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Career value in variable
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

}