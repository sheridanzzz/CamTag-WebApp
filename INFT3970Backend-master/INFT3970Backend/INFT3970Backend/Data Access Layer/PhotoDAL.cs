///-----------------------------------------------------------------
///   Class:        PhotoDAL
///   
///   Description:  The DataAccessLayer for all Photo updates in the database.
///                 Extends the base DataAccessLayer class.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using System.Collections.Generic;
using INFT3970Backend.Models;
using System.Data.SqlClient;

namespace INFT3970Backend.Data_Access_Layer
{
    public class PhotoDAL : DataAccessLayer
    {
        public PhotoDAL() { }



        /// <summary>
        /// Saves a photo to the database, creates all PlayerVotePhoto records and returns the created Photo record in the DB.
        /// </summary>
        /// <param name="photo">The photo object to save to the database.</param>
        /// <param name="isBR">A flag value which outlines if the photo being uploaded is apart of a BR game.</param>
        /// <returns>The created Photo object saved to the database.</returns>
        public Response<Photo> SavePhoto(Photo photoToSave, bool isBR)
        {
            if(isBR)
                StoredProcedure = "usp_BR_SavePhoto";
            else
                StoredProcedure = "usp_SavePhoto";
            Photo photo = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("dataURL", photoToSave.PhotoDataURL);
                        AddParam("takenByID", photoToSave.TakenByPlayerID);
                        AddParam("photoOfID", photoToSave.PhotoOfPlayerID);
                        AddParam("lat", photoToSave.Lat);
                        AddParam("long", photoToSave.Long);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            ModelFactory factory = new ModelFactory(Reader);
                            photo = factory.PhotoFactory(false, false, false);
                            if (photo == null)
                                return new Response<Photo>("An error occurred while trying to build the photo model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Photo>(photo, ErrorMSG, Result);
                    }
                }
            }
            catch
            {
                return Response<Photo>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Get the last photo taken by each player in order to retrieve each players last known location.
        /// </summary>
        /// <param name="player">The player making the request.</param>
        /// <returns>A list of photos containing each other players in the game last taken photo.</returns>
        public Response<List<Photo>> GetLastKnownLocations(Player player)
        {
            StoredProcedure = "usp_GetLastKnownLocations";
            List<Photo> photos = new List<Photo>();
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        ModelFactory factory = new ModelFactory(Reader);
                        while (Reader.Read())
                        {
                            Photo photo = factory.PhotoFactory(true, true, false);
                            if (photo == null)
                                return new Response<List<Photo>>("An error occurred while trying to build the list photo model.", ErrorCodes.BUILD_MODEL_ERROR);

                            photos.Add(photo);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<List<Photo>>(photos, ErrorMSG, Result);
                    }
                }
            }
            catch
            {
                return Response<List<Photo>>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Gets a photo from the database matching the specified ID.
        /// Returns the Photo matching the ID.
        /// </summary>
        /// <param name="id">The ID of the photo to get.</param>
        /// <returns>The photo object matching the passed in ID</returns>
        public Photo GetPhotoByID(int id)
        {
            StoredProcedure = "usp_GetPhotoByID";
            Photo photo = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        
                        AddParam("photoID", id);

                        //Perform the procedure and get the result
                        RunReader();
                        

                        while (Reader.Read())
                        {
                            ModelFactory factory = new ModelFactory(Reader);
                            photo = factory.PhotoFactory(true, true, true);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        return photo;
                    }
                }
            }
            catch
            {
                return null;
            }
        }





        /// <summary>
        /// Updates the photo record after the voting time has expried. If all players
        /// have not voted on the photo it is an automatic successful photo.
        /// Returns the updated photo record. NULL if error or ID does not exist.
        /// </summary>
        /// <param name="photoID">The ID of the photo to update.</param>
        /// <param name="isBR">A flag value which outlines if the game is a BR game.</param>
        /// <returns>The updated photo object.</returns>
        public Response<Photo> VotingTimeExpired(int photoID, bool isBR)
        {
            if (isBR)
                StoredProcedure = "usp_BR_VotingTimeExpired";
            else
                StoredProcedure = "usp_VotingTimeExpired";
            Photo photo = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("photoID", photoID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            ModelFactory factory = new ModelFactory(Reader);
                            photo = factory.PhotoFactory(true, true, true);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Photo>(photo, ErrorMSG, Result);
                    }
                }
            }
            catch
            {
                return Response<Photo>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// Gets the list of votes the player must complete / the Vote records which have not been completed by the player.
        /// </summary>
        /// <param name="player">The player who votes to complete are being obtained.</param>
        /// <returns>The list of votes the player must complete before continuing to play the game.</returns>
        public Response<List<Vote>> GetVotesToComplete(Player player)
        {
            StoredProcedure = "usp_GetVotesToComplete";
            List<Vote> list = new List<Vote>();
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            Vote playerVotePhoto = new ModelFactory(Reader).VoteFactory(true, true);
                            if (playerVotePhoto == null)
                                return new Response<List<Vote>>("An error occurred while trying to build the model.", ErrorCodes.BUILD_MODEL_ERROR);
                            else
                                list.Add(playerVotePhoto);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<List<Vote>>(list, ErrorMSG, Result);
                    }
                }
            }
            catch
            {
                return Response<List<Vote>>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// The player casts their vote on the photo, outlining if the photo is successful or not.
        /// </summary>
        /// <param name="playerVote">The vote being casted.</param>
        /// <param name="isBR">A flag which outlines if the game is a BR game.</param>
        /// <returns>The updated Vote object.</returns>
        public Response<Vote> VoteOnPhoto(Vote playerVote, bool isBR)
        {
            if (isBR)
                StoredProcedure = "usp_BR_VoteOnPhoto";
            else
                StoredProcedure = "usp_VoteOnPhoto";
            Vote playerVotePhoto = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("voteID", playerVote.VoteID);
                        AddParam("playerID", playerVote.PlayerID);
                        AddParam("isPhotoSuccessful", playerVote.IsPhotoSuccessful);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            playerVotePhoto = new ModelFactory(Reader).VoteFactory(true, true);
                            if (playerVotePhoto == null)
                                return new Response<Vote>("An error occurred while trying to build the model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Vote>(playerVotePhoto, ErrorMSG, Result);
                    }
                }
            }
            catch
            {
                return Response<Vote>.DatabaseErrorResponse();
            }
        }
    }
}
