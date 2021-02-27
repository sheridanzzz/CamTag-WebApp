///-----------------------------------------------------------------
///   Class:        Photo
///   
///   Description:  A model which represents a Photo submitted by 
///                 a player in CamTag. Maps to the data found in 
///                 the Database and has business logic validation
///                 checking.
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
    public class Photo
    {
        //Private backing stores of public properites which have business logic behind them.
        private int photoID;
        private double lat;
        private double longitude;
        private string photoDataURL;
        private int numYesVotes;
        private int numNoVotes;
        private int gameID;
        private int takenByPlayerID;
        private int photoOfPlayerID;



        /// <summary>
        /// The photoID
        /// </summary>
        public int PhotoID
        {
            get { return photoID; }
            set
            {
                string errorMessage =  "PhotoID must be atleast 100000.";

                //Confirm the photoID is within the valid range, can be -1 if creating a photo without and ID yet
                if (value == -1 || value >= 100000)
                    photoID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// The latitude value where the photo was taken.
        /// </summary>
        public double Lat
        {
            get { return lat; }
            set
            {
                string errorMessage = "Latitude is not within the valid range. Must be -90 to +90";

                //Confirm the latitude is within the valid range.
                if (value >= -90 && value <= 90)
                    lat = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// The longittude value where the photo was taken.
        /// </summary>
        public double Long
        {
            get { return longitude; }
            set
            {
                string errorMessage = "Longitude is not within the valid range. Must be -180 to +180";

                //Confirm the longitude is within the valid range.
                if (value >= -180 && value <= 180)
                    longitude = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }




        /// <summary>
        /// The DataURL base64 image data when the player takes a photo.
        /// </summary>
        public string PhotoDataURL
        {
            get { return photoDataURL; }
            set
            {
                string errorMessage = "PhotoDataURL is not a base64 string.";

                //If the value is null return
                if (value == null)
                {
                    photoDataURL = value;
                    return;
                }

                //If the dataURL is just whitespace throw an error
                if (string.IsNullOrWhiteSpace(value))
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);

                //Confirm the imgURL is a base64 string
                try
                {
                    if (!value.Contains("data:image/jpeg;base64,"))
                        throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);

                    string base64Data = value.Replace("data:image/jpeg;base64,", "");
                    byte[] byteData = Convert.FromBase64String(base64Data);
                    photoDataURL = value;
                }
                catch
                {
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
                }
            }
        }




        /// <summary>
        /// The number of Yes votes submitted on the photo
        /// </summary>
        public int NumYesVotes
        {
            get { return numYesVotes; }
            set
            {
                string errorMessage = "Number of yes votes cannot be below 0.";

                //Confirm the value is within the valid range.
                if (value < 0)
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
                else
                    numYesVotes = value;
            }
        }



        /// <summary>
        /// The number of No votes submitted on the photo
        /// </summary>
        public int NumNoVotes
        {
            get { return numNoVotes; }
            set
            {
                string errorMessage = "Number of no votes cannot be below 0.";

                if (value < 0)
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
                else
                    numNoVotes = value;
            }
        }
        



        /// <summary>
        /// The ID of the Game the photo belongs to.
        /// </summary>
        public int GameID
        {
            get { return gameID; }
            set
            {
                string errorMessage = "GameID must be atleast 100000.";

                //Confirm the value is within the valid range.
                if (value == -1 || value >= 100000)
                    gameID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// The ID player who took the photo
        /// </summary>
        public int TakenByPlayerID
        {
            get { return takenByPlayerID; }
            set
            {
                string errorMessage = "TakenByPlayerID must be atleast 100000.";

                //Confirm the value is within the valid range.
                if (value == -1 || value >= 100000)
                    takenByPlayerID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// The ID player who the photo is of
        /// </summary>
        public int PhotoOfPlayerID
        {
            get { return photoOfPlayerID; }
            set
            {
                string errorMessage = "photoOfPlayerID must be atleast 100000.";

                //Confirm the value is within the valid range.
                if (value == -1 || value >= 100000)
                    photoOfPlayerID = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }


        /// <summary>
        /// A flag which outlines if the photo is a successful photo of the other player
        /// </summary>
        public bool IsSuccessful
        {
            get
            {
                //If the voting is not complete then return false, otherwise, compare the yes and no votes
                if (!IsVotingComplete)
                    return false;
                else
                    return NumYesVotes > NumNoVotes;
            }
        }


        /// <summary>
        /// The DateTime the photo was taken
        /// </summary>
        public DateTime TimeTaken { get; set; }

        /// <summary>
        /// The DateTime when the voting time will finish
        /// </summary>
        public DateTime VotingFinishTime { get; set; }

        /// <summary>
        /// A flag which outlines if the photo voting is commpleted
        /// </summary>
        public bool IsVotingComplete { get; set; }

        /// <summary>
        /// A flag if the game is active
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// A flag if the game is deleted
        /// </summary>
        public bool IsDeleted { get; set; }

        /// <summary>
        /// The game the photo is apart of
        /// </summary>
        public Game Game { get; set; }

        /// <summary>
        /// The player who took the photo
        /// </summary>
        public Player TakenByPlayer { get; set; }

        /// <summary>
        /// The player who the photo is of
        /// </summary>
        public Player PhotoOfPlayer { get; set; }
        


        /// <summary>
        /// Creates a Photo with default values
        /// </summary>
        public Photo()
        {
            PhotoID = -1;
            GameID = -1;
            TakenByPlayerID = -1;
            PhotoOfPlayerID = -1;
            PhotoDataURL = null;
            TimeTaken = DateTime.Now;
            VotingFinishTime = DateTime.Now.AddMinutes(15);
            IsActive = true;
        }



        /// <summary>
        /// Creates a photo with default values and sets the following properties.
        /// </summary>
        /// <param name="lat">Latitude</param>
        /// <param name="longitude">Longitude</param>
        /// <param name="photoDataURL">The DataURL of the photo, base64 string</param>
        /// <param name="takenByPlayerID">The ID of the player who took the photo</param>
        /// <param name="photoOfPlayerID">The ID of the player who the photo is of</param>
        public Photo(double lat, double longitude, string photoDataURL, int takenByPlayerID, int photoOfPlayerID) : this()
        {
            Lat = lat;
            Long = longitude;
            PhotoDataURL = photoDataURL;
            TakenByPlayerID = takenByPlayerID;
            PhotoOfPlayerID = photoOfPlayerID;
        }



        /// <summary>
        /// Creates a photo with default values and sets the following properties.
        /// </summary>
        /// <param name="lat">Latitude</param>
        /// <param name="longitude">Longitude</param>
        /// <param name="photoDataURL">The DataURL of the photo, base64 string</param>
        /// <param name="takenByPlayerID">The ID of the player who took the photo</param>
        /// <param name="photoOfPlayerID">The ID of the player who the photo is of</param>
        public Photo(string lat, string longitude, string photoDataURL, string takenByPlayerID, string photoOfPlayerID) :this()
        {
            PhotoDataURL = photoDataURL;

            try
            {
                Lat = double.Parse(lat);
                Long = double.Parse(longitude);
                TakenByPlayerID = int.Parse(takenByPlayerID);
                PhotoOfPlayerID = int.Parse(photoOfPlayerID);
            }
            catch(FormatException)
            {
                string errorMessage = "Lat, long, takenByPlayerID or photoOfID is invalid format. Must be numbers.";
                throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// Compress the photo for the Map request, when the player request to view the map. 
        /// The only photo required is the small selfie for the map display. So the actual photo
        /// can be removed and the user's large and medium selfie can be removed for network performance.
        /// </summary>
        public void CompressForMapRequest()
        {
            PhotoDataURL = null;

            //Compress the player object to remove all the photos except for the extraSmallPhoto
            if (TakenByPlayer != null)
                TakenByPlayer.Compress(true, true, false);

            if (PhotoOfPlayer != null)
                PhotoOfPlayer.Compress(true, true, true);
        }


        /// <summary>
        /// Compress the photo for voting request. The only photos required 
        /// are the actual photo taken and the photoOfPlayer's large selfie.
        /// All other photo sizes can be compressed for network performance.
        /// </summary>
        public void CompressForVoting()
        {
            //Compress the taken by player as its not needed for voting
            if (TakenByPlayer != null)
                TakenByPlayer.Compress(true, true, true);

            //Compress the photo of player but keep their large selfie
            if (PhotoOfPlayer != null)
                PhotoOfPlayer.Compress(false, true, true);
        }
    }
}
