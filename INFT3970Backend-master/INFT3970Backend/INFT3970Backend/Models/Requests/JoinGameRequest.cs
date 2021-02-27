///-----------------------------------------------------------------
///   Class:        JoinGameRequest
///   
///   Description:  An object which encapsulates a request sent by the 
///                 front end when joining a game. The front end
///                 will create a JSON object and send the object
///                 to the back end. The JSON object translates to this object.
///                 
///                 This class matches all the player information and 
///                 game code the player enters when joining a game.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------
namespace INFT3970Backend.Models.Requests
{
    public class JoinGameRequest
    {
        public string gameCode { get; set; }
        public string nickname { get; set; }
        public string contact { get; set; }
        public string imgUrl { get; set; }
    }
}
