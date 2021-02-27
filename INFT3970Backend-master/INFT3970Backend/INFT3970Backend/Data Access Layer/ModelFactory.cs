///-----------------------------------------------------------------
///   Class:        ModelFactory
///   
///   Description:  A helper class for the DataAccessLayers in order to
///                 build the strongly typed objects from the database data.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using System;
using System.Data.SqlClient;
using INFT3970Backend.Models;

namespace INFT3970Backend.Data_Access_Layer
{
    public class ModelFactory
    {
        /// <summary>
        /// The reader which contains the data to build the model.
        /// </summary>
        private SqlDataReader Reader;



        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="reader">The SQL DataReader which will be used to read objects</param>
        public ModelFactory(SqlDataReader reader)
        {
            Reader = reader;
        }



        /// <summary>
        /// Gets the index of the column with the specified column name.
        /// </summary>
        /// <param name="colName">The name of the column.</param>
        /// <returns>The column index if found, negative INT if the column name does not exist within the reader.</returns>
        private int GetColIndex(string colName)
        {
            try
            {
                return Reader.GetOrdinal(colName);
            }
            catch
            {
                return -1;
            }
        }



        /// <summary>
        /// Gets an INT value from the column.
        /// </summary>
        /// <param name="colName">The column name containing the INT value</param>
        /// <returns>The INT value found inside the column</returns>
        private int GetInt(string colName)
        {
            return Reader.GetInt32(GetColIndex(colName));
        }



        /// <summary>
        /// Gets a BOOL value from the column
        /// </summary>
        /// <param name="colName">The column name containing the BOOL value</param>
        /// <returns>The BOOL value found inside the column</returns>
        private bool GetBool(string colName)
        {
            return Reader.GetBoolean(GetColIndex(colName));
        }



        /// <summary>
        /// Gets a DOUBLE value from the column
        /// </summary>
        /// <param name="colName">The column name containing the DOUBLE value</param>
        /// <returns>The DOUBLE value found inside the column</returns>
        private double GetDouble(string colName)
        {
            return Reader.GetDouble(GetColIndex(colName));
        }




        /// <summary>
        /// Gets a DATETIME value from the column
        /// </summary>
        /// <param name="colName">The column name containing the DATETIME value</param>
        /// <returns>The DATETIME value found inside the column</returns>
        private DateTime GetDateTime(string colName)
        {
            return Reader.GetDateTime(GetColIndex(colName));
        }





        /// <summary>
        /// Safely get a BOOL value from the column. Will return NULL if the column value is NULL
        /// </summary>
        /// <param name="colName"></param>
        /// <returns>The BOOL value found inside the column or NULL if the column is null</returns>
        private bool? SafeGetBool(string colName)
        {
            int index = GetColIndex(colName);
            if (!Reader.IsDBNull(index))
                return Reader.GetBoolean(index);
            else
                return null;
        }




        /// <summary>
        /// Safely get a STRING value from the column. Will return STRING.EMPTY if the column value is NULL
        /// </summary>
        /// <param name="colName"></param>
        /// <returns>The STRING value found inside the column or STRING.EMPTY if the column is null</returns>
        private string SafeGetString(string colName)
        {
            int index = GetColIndex(colName);
            if (!Reader.IsDBNull(index))
                return Reader.GetString(index);
            return string.Empty;
        }



        /// <summary>
        /// Safely get a DATETIME value from the column. Will return NULL if the column value is NULL
        /// </summary>
        /// <param name="colName"></param>
        /// <returns>The DATETIME value found inside the column or NULL if the column is null</returns>
        private DateTime? SafeGetDateTime(string colName)
        {
            int index = GetColIndex(colName);
            if (!Reader.IsDBNull(index))
                return Reader.GetDateTime(index);
            else
                return null;
        }

        

        

        /// <summary>
        /// Builds a Notification Model from the data reader.
        /// </summary>
        /// <returns>A Notification object, NULL if an error occurred while trying to build the object.</returns>
        public Notification NotificationFactory()
        {
            try
            {
                Notification notification = new Notification();
                notification.NotificationID = GetInt("NotificationID");
                notification.MessageText = SafeGetString("MessageText");
                notification.Type = SafeGetString("NotificationType");
                notification.IsRead = GetBool("IsRead");
                notification.IsActive = GetBool("NotificationIsActive");
                notification.IsDeleted = GetBool("NotificationIsDeleted");
                notification.GameID = GetInt("GameID");
                notification.PlayerID = GetInt("PlayerID");
                return notification;
            }
            catch
            {
                return null;
            }
        }






        /// <summary>
        /// Builds a Player Model from the data reader.
        /// </summary>
        /// <param name="doGetGame">A flag which outlines if also building the Game model inside the player.</param>
        /// <returns>A Player object, NULL if an error occurred while trying to build the object.</returns>
        public Player PlayerFactory(bool doGetGame)
        {
            try
            {
                Player player = new Player();
                player.PlayerID = GetInt("PlayerID");
                player.Nickname = SafeGetString("Nickname");
                player.Phone = SafeGetString("Phone");
                player.Email = SafeGetString("Email");
                player.Selfie = SafeGetString("Selfie");
                player.SmallSelfie = SafeGetString("SmallSelfie");
                player.ExtraSmallSelfie = SafeGetString("ExtraSmallSelfie");
                player.AmmoCount = GetInt("AmmoCount");
                player.NumKills = GetInt("NumKills");
                player.NumDeaths = GetInt("NumDeaths");
                player.IsHost = GetBool("IsHost");
                player.IsVerified = GetBool("IsVerified");
                player.ConnectionID = SafeGetString("ConnectionID");
                player.HasLeftGame = GetBool("HasLeftGame");
                player.IsActive = GetBool("PlayerIsActive");
                player.IsDeleted = GetBool("PlayerIsDeleted");
                player.GameID = GetInt("GameID");
                player.PlayerType = SafeGetString("PlayerType");
                player.IsEliminated = GetBool("IsEliminated");
                player.IsDisabled = GetBool("IsDisabled");

                //Build the Game object for the player
                if (doGetGame)
                    player.Game = GameFactory();

                return player;
            }
            catch
            {
                return null;
            }
        }






        /// <summary>
        /// Builds a Photo Model from the data reader.
        /// </summary>
        /// <param name="doGetGame">A flag which outlines if also building the Game model inside the photo.</param>
        /// <param name="doGetPlayerWhoTookPhoto">A flag which outlines if also building the Player model who took the photo.</param>
        /// <param name="doGetPlayerWhoPhotoIsOf">A flag which outlines if also building the Player model who the photo is of.</param>
        /// <returns>A Player object, NULL if an error occurred while trying to build the object.</returns>
        public Photo PhotoFactory(bool doGetGame, bool doGetPlayerWhoTookPhoto, bool doGetPlayerWhoPhotoIsOf)
        {
            try
            {
                //Build the Photo Object
                Photo photo = new Photo();
                photo.PhotoID = GetInt("PhotoID");
                photo.Lat = GetDouble("Lat");        
                photo.Long = GetDouble("Long");
                photo.PhotoDataURL = SafeGetString("PhotoDataURL");
                photo.TimeTaken = GetDateTime("TimeTaken");
                photo.VotingFinishTime = GetDateTime("VotingFinishTime");
                photo.NumYesVotes = GetInt("NumYesVotes");
                photo.NumNoVotes = GetInt("NumNoVotes");
                photo.IsVotingComplete = GetBool("IsVotingComplete");
                photo.IsActive = GetBool("PhotoIsActive");
                photo.IsDeleted = GetBool("PhotoIsDeleted");
                photo.GameID = GetInt("GameID");
                photo.TakenByPlayerID = GetInt("TakenByPlayerID");
                photo.PhotoOfPlayerID = GetInt("PhotoOfPlayerID");

                //Build the game object if you need to get the game
                if (doGetGame)
                    photo.Game = GameFactory();

                //Build the taken by player object
                if(doGetPlayerWhoTookPhoto)
                {
                    Player player = new Player();
                    player.PlayerID = photo.TakenByPlayerID;
                    player.Nickname = SafeGetString("TakenByPlayerNickname");
                    player.Phone = SafeGetString("TakenByPlayerPhone");
                    player.Email = SafeGetString("TakenByPlayerEmail");
                    player.Selfie = SafeGetString("TakenByPlayerSelfie");
                    player.SmallSelfie = SafeGetString("TakenByPlayerSmallSelfie");
                    player.ExtraSmallSelfie = SafeGetString("TakenByPlayerExtraSmallSelfie");
                    player.AmmoCount = GetInt("TakenByPlayerAmmoCount");
                    player.NumKills = GetInt("TakenByPlayerNumKills");
                    player.NumDeaths = GetInt("TakenByPlayerNumDeaths");
                    player.IsHost = GetBool("TakenByPlayerIsHost");
                    player.IsVerified = GetBool("TakenByPlayerIsVerified");
                    player.ConnectionID = SafeGetString("TakenByPlayerConnectionID");
                    player.HasLeftGame = GetBool("TakenByPlayerHasLeftGame");
                    player.IsActive = GetBool("TakenByPlayerIsActive");
                    player.IsDeleted = GetBool("TakenByPlayerIsDeleted");
                    player.IsDisabled = GetBool("TakenByPlayerIsDisabled");
                    player.Game = null;
                    photo.TakenByPlayer = player;
                }


                //Build the photo of player object
                if (doGetPlayerWhoTookPhoto)
                {
                    Player player = new Player();
                    player.PlayerID = photo.PhotoOfPlayerID;
                    player.Nickname = SafeGetString("PhotoOfPlayerNickname");
                    player.Phone = SafeGetString("PhotoOfPlayerPhone");
                    player.Email = SafeGetString("PhotoOfPlayerEmail");
                    player.Selfie = SafeGetString("PhotoOfPlayerSelfie");
                    player.SmallSelfie = SafeGetString("PhotoOfPlayerSmallSelfie");
                    player.ExtraSmallSelfie = SafeGetString("PhotoOfPlayerExtraSmallSelfie");
                    player.AmmoCount = GetInt("PhotoOfPlayerAmmoCount");
                    player.NumKills = GetInt("PhotoOfPlayerNumKills");
                    player.NumDeaths = GetInt("PhotoOfPlayerNumDeaths");
                    player.IsHost = GetBool("PhotoOfPlayerIsHost");
                    player.IsVerified = GetBool("PhotoOfPlayerIsVerified");
                    player.ConnectionID = SafeGetString("PhotoOfPlayerConnectionID");
                    player.HasLeftGame = GetBool("PhotoOfPlayerHasLeftGame");
                    player.IsActive = GetBool("PhotoOfPlayerIsActive");
                    player.IsDeleted = GetBool("PhotoOfPlayerIsDeleted");
                    player.IsDisabled = GetBool("PhotoOfPlayerIsDisabled");
                    player.Game = null;
                    photo.PhotoOfPlayer = player;
                }

                return photo;
            }
            catch
            {
                return null;
            }
        }






        /// <summary>
        /// Builds a Game Model from the data reader.
        /// </summary>
        /// <returns>A Game object, NULL if an error occurred while trying to build the object.</returns>
        public Game GameFactory()
        {
            try
            {
                Game game = new Game();
                game.GameID = GetInt("GameID");
                game.GameCode = SafeGetString("GameCode");
                game.NumOfPlayers = GetInt("NumOfPlayers");
                game.GameMode = SafeGetString("GameMode");
                game.StartTime = SafeGetDateTime("StartTime");
                game.EndTime = SafeGetDateTime("EndTime");
                game.GameState = SafeGetString("GameState");
                game.IsJoinableAtAnytime = GetBool("IsJoinableAtAnytime");
                game.IsActive = GetBool("GameIsActive");
                game.IsDeleted = GetBool("GameIsDeleted");
                game.AmmoLimit = GetInt("AmmoLimit");
                game.ReplenishAmmoDelay = GetInt("ReplenishAmmoDelay");
                game.StartDelay = GetInt("StartDelay");
                game.Latitude = GetDouble("Latitude");
                game.Longitude = GetDouble("Longitude");
                game.Radius = GetInt("Radius");
                return game;
            }
            catch
            {
                return null;
            }
        }








        /// <summary>
        /// Builds a Vote Model from the data reader.
        /// </summary>
        /// <param name="doGetPlayer">A flag which outlines if also building the Player model.</param>
        /// <param name="doGetPhoto">A flag which outlines if also building the Photo model.</param>
        /// <returns></returns>
        public Vote VoteFactory(bool doGetPlayer, bool doGetPhoto)
        {
            try
            {
                Player player = null;
                Photo photo = null;

                //Build the PlayerVotePhoto object
                Vote playerVotePhoto = new Vote();
                playerVotePhoto.VoteID = GetInt("VoteID");
                playerVotePhoto.IsPhotoSuccessful = SafeGetBool("IsPhotoSuccessful");
                playerVotePhoto.IsActive = GetBool("VoteIsActive");
                playerVotePhoto.PlayerID = GetInt("PlayerID");
                playerVotePhoto.PhotoID = GetInt("PhotoID");
                playerVotePhoto.IsDeleted = GetBool("VoteIsDeleted");

                if (doGetPlayer)
                    player = PlayerFactory(true);
                if (doGetPhoto)
                    photo = PhotoFactory(true, true, true);

                playerVotePhoto.Photo = photo;
                playerVotePhoto.Player = player;
                return playerVotePhoto;
            }
            catch
            {
                return null;
            }
        }
    }
}
    

