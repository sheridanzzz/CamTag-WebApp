///-----------------------------------------------------------------
///   Class:        GameStatusResponse
///   
///   Description:  An object which encapsulates a response sent by the 
///                 back end when the front end request an application status update.
///                 
///                 This response is returned when a client reloads
///                 the application and needs to be updated on game status
///                 and items to complete etc.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------
namespace INFT3970Backend.Models.Responses
{
    public class GameStatusResponse
    {
        /// <summary>
        /// Flag which outlines if the player has votes to complete after returning to the game
        /// </summary>
        public bool HasVotesToComplete { get; set; }

        /// <summary>
        /// Flag which outlines if the player has new notification after returning to the game
        /// </summary>
        public bool HasNotifications { get; set; }

        /// <summary>
        /// The player reconnecting, used to confirm game state and other details about the player.
        /// </summary>
        public Player Player { get; set; }


        public GameStatusResponse(bool hasVotesToComplete, bool hasNotifications, Player player)
        {
            HasVotesToComplete = hasVotesToComplete;
            HasNotifications = hasNotifications;
            Player = player;
        }

        public void Compress()
        {
            if (Player != null)
                Player.Compress(true, true, true);
        }
    }
}
