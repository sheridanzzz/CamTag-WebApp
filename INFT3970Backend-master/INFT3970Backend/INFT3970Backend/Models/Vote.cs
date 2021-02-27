///-----------------------------------------------------------------
///   Class:        Vote
///   
///   Description:  A model which represents a Vote in CamTag.
///                 A vote is a players decision on a photo submitted
///                 during a game, either successful or unsuccessful.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using INFT3970Backend.Models.Errors;
using System;

namespace INFT3970Backend.Models
{
    public class Vote
    {
        //Private backing stores for public properties
        private int voteID;
        private int playerID;
        private int photoID;


        /// <summary>
        /// The ID of the vote.
        /// </summary>
        public int VoteID
        {
            get { return voteID; }
            set
            {
                string errorMessage = "VoteID must be atleast 100000.";

                //Confirm within valid range
                if (value == -1 || value >= 100000)
                    voteID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_VOTE);
            }
        }


        
        /// <summary>
        /// The ID of the player who must vote.
        /// </summary>
        public int PlayerID
        {
            get { return playerID; }
            set
            {
                string errorMessage = "PlayerID must be atleast 100000.";

                //Confirm within valid range
                if (value == -1 || value >= 100000)
                    playerID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_VOTE);
            }
        }



        /// <summary>
        /// The ID the photo the player is voting on.
        /// </summary>
        public int PhotoID
        {
            get { return photoID; }
            set
            {
                string errorMessage = "PhotoID must be atleast 100000.";

                //Confirm the ID is within a valid range
                if (value == -1 || value >= 100000)
                    photoID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_VOTE);
            }
        }


        /// <summary>
        /// A flag outlining if the photo is successful or not
        /// </summary>
        public bool? IsPhotoSuccessful { get; set; }

        /// <summary>
        /// A flag outlining if the vote is active
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// A flag which outlines if the vote is deleted
        /// </summary>
        public bool IsDeleted { get; set; }

        /// <summary>
        /// The player who must vote.
        /// </summary>
        public Player Player { get; set; }

        /// <summary>
        /// The photo the player is voting on
        /// </summary>
        public Photo Photo { get; set; }





        /// <summary>
        /// Creates a Vote with the default values
        /// </summary>
        public Vote()
        {
            VoteID = -1;
            PlayerID = -1;
            PhotoID = -1;
            IsActive = true;
            IsDeleted = false;
            IsPhotoSuccessful = null;
        }




        /// <summary>
        /// Creates a Vote with the default values and sets the following properties.
        /// </summary>
        /// <param name="voteID">The ID of the vote</param>
        /// <param name="isPhotoSuccessful">The decision of the vote, true or false/param>
        /// <param name="playerID">The ID of the player who is casting the vote.</param>
        public Vote(int voteID, bool? isPhotoSuccessful, int playerID) : this()
        {
            VoteID = voteID;
            IsPhotoSuccessful = isPhotoSuccessful;
            PlayerID = playerID;
        }




        /// <summary>
        /// Creates a Vote with the default values and sets the following properties.
        /// </summary>
        /// <param name="voteID">The ID of the vote</param>
        /// <param name="isPhotoSuccessful">The decision of the vote, true or false/param>
        /// <param name="playerID">The ID of the player who is casting the vote.</param>
        public Vote(int voteID, string isPhotoSuccessful, int playerID) : this()
        {
            VoteID = voteID;
            PlayerID = playerID;
            try
            {
                IsPhotoSuccessful = bool.Parse(isPhotoSuccessful);
            }
            catch(FormatException)
            {
                string errorMessage = "IsPhotoSuccessful can only be true or false, received " + isPhotoSuccessful;
                throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_VOTE);
            }
        }



        /// <summary>
        /// Compress the vote before sending over the network to improve performance.
        /// </summary>
        public void Compress()
        {
            //If the player is not null compress the entire player as no selfies of the player voting are needed.
            if (Player != null)
                Player.Compress(true, true, true);

            //Compress the photo
            if (Photo != null)
                Photo.CompressForVoting();
        }
    }
}
