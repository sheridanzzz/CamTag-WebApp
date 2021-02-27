///-----------------------------------------------------------------
///   Class:        HubInterface
///   
///   Description:  This class is all the error codes the application produces
///                 and sends to the front end to handle when an error
///                 occurs on the backend and database.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

namespace INFT3970Backend.Models
{
    public class ErrorCodes
    {
        //General / Global Error Codes
        public const int DATABASE_CONNECT_ERROR = 0;
        public const int INSERT_ERROR = 2;
        public const int BUILD_MODEL_ERROR = 3;
        public const int ITEM_ALREADY_EXISTS = 4;
        public const int DATA_INVALID = 5;
        public const int ITEM_DOES_NOT_EXIST = 6;
        public const int CANNOT_PERFORM_ACTION = 7;
        public const int GAME_DOES_NOT_EXIST = 8;
        public const int GAME_STATE_INVALID = 9;
        public const int PLAYER_DOES_NOT_EXIST = 10;
        public const int PLAYER_INVALID = 11;
        public const int MODELINVALID_PLAYER = 12;
        public const int MODELINVALID_GAME = 13;
        public const int MODELINVALID_PHOTO = 14;
        public const int MODELINVALID_VOTE = 15;


        //Battle Royal Error Codes
        public const int BR_PLAYERELIMINATED = 100;
        public const int BR_NOTINZONE = 101;
    }
}
