///-----------------------------------------------------------------
///   Class:        CreateGameRequest
///   
///   Description:  An object which encapsulates a request sent by the 
///                 front end when creating a game. The front end
///                 will create a JSON object and send the object
///                 to the back end. The JSON object translates to this object.
///                 
///                 This class matches all the player information and 
///                 game setting options the player has when creating a game.
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
    public class CreateGameRequest
    {
        public string nickname { get; set; }
        public string contact { get; set; }
        public string imgUrl { get; set; }
        public int timeLimit { get; set; }
        public int ammoLimit { get; set; }
        public int startDelay { get; set; }
        public int replenishAmmoDelay { get; set; }
        public string gameMode { get; set; }
        public bool isJoinableAtAnytime { get; set; }

        //Game settings for the battle royal game mode
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int Radius { get; set; }
    }
}
