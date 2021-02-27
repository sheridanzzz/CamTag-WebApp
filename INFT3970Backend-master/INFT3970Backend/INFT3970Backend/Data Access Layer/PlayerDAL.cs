///-----------------------------------------------------------------
///   Class:        PlayerDAL
///   
///   Description:  The DataAccessLayer for all Player updates in the database.
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

using INFT3970Backend.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace INFT3970Backend.Data_Access_Layer
{
    public class PlayerDAL: DataAccessLayer
    {
        public PlayerDAL()
        {

        }



        /// <summary>
        /// Get a Player object with the specified ID. Inluding a deleted player.
        /// </summary>
        /// <param name="id">The ID of the player</param>
        /// <returns>The Player object, NULL if an errror occurred</returns>
        public Response<Player> GetPlayerByID(int id)
        {
            StoredProcedure = "usp_GetPlayerByID";
            Player player = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", id);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            player = new ModelFactory(Reader).PlayerFactory(true);
                            if(player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }





        /// <summary>
        /// Updates the specified playerID's connectionID inside the database.
        /// Sets the ConnectionID to the ID passed in and sets IsConnected = TRUE
        /// </summary>
        /// <param name="player">The player being updated</param>
        public void UpdateConnectionID(Player player)
        {
            StoredProcedure = "usp_UpdateConnectionID";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddParam("connectionID", player.ConnectionID);
                        AddDefaultParams();
                        
                        //Perform the procedure and get the result
                        Run();
                    }
                }
            }

            //A database exception was thrown
            catch
            {
                //Do nothing
            }
        }







        /// <summary>
        /// Adds the player to the game matching the gamecode passed in.
        /// Returns the created Player object. NULL data if error occurred.
        /// </summary>
        /// <param name="game">The game the player is joining.</param>
        /// <param name="player">The player joining the game.</param>
        /// <param name="verificationCode">The players verification which the player needs to verify.</param>
        /// <returns>The created player object.</returns>
        public Response<Player> JoinGame(Game game, Player player, int verificationCode)
        {
            StoredProcedure = "usp_JoinGame";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameCode", game.GameCode);
                        AddParam("nickname", player.Nickname);
                        AddParam("contact", player.GetContact());
                        AddParam("selfie", player.Selfie);
                        AddParam("smallSelfie", player.SmallSelfie);
                        AddParam("extraSmallSelfie", player.ExtraSmallSelfie);
                        AddParam("isPhone", player.HasPhone());
                        AddParam("verificationCode", verificationCode);
                        AddParam("isHost", player.IsHost);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while(Reader.Read())
                        {
                            player = new ModelFactory(Reader).PlayerFactory(true);
                            if (player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();

                        if (IsError)
                            player = null;
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Confirms the validation code entered by the player matches what is stored against their player record.
        /// If the player successfully enters the validation code their player record will be set to "Verified"
        /// </summary>
        /// <param name="verificationCode">The verification code to confirm is correct</param>
        /// <param name="player">The player to verify.</param>
        /// <returns>The updated player record.</returns>
        public Response<Player> ValidateVerificationCode(int verificationCode, Player player)
        {
            StoredProcedure = "usp_ValidateVerificationCode";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("verificationCode", verificationCode);
                        AddParam("playerID", player.PlayerID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            player = new ModelFactory(Reader).PlayerFactory(true);
                            if (player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// Updates the Player's verification code.
        /// </summary>
        /// <param name="player">The player who's verification code is being updated</param>
        /// <param name="verificationCode">The new verification code</param>
        /// <returns>The updated player record.</returns>
        public Response<Player> UpdateVerificationCode(Player player, int verificationCode)
        {
            StoredProcedure = "usp_UpdateVerificationCode";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("verificationCode", verificationCode);
                        AddParam("playerID", player.PlayerID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while(Reader.Read())
                        {
                            player = new ModelFactory(Reader).PlayerFactory(false);
                            if (player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }





        /// <summary>
        /// Removes the ConnectionID from the Player record when the player disconnects from the application hub.
        /// Sets the player's ConnectionID to NULL and IsConnected to FALSE.
        /// </summary>
        /// <param name="connectionID">The connectionID to remove.</param>
        public void RemoveConnectionID(string connectionID)
        {
            StoredProcedure = "usp_RemoveConnectionID";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("connectionID", connectionID);
                        //Perform the procedure and get the result
                        Run();
                    }
                }
            }

            //A database exception was thrown
            catch
            {
                //Do nothing
            }
        }





        /// <summary>
        /// Gets the list of notifications for the player, ordered by most recent.
        /// </summary>
        /// <param name="player">The player whos notifications are being retrieved.</param>
        /// <param name="all">A flag value which outlines if should get all notifications or just unread notifications.</param>
        /// <returns>The list of players notifications.</returns>
        public Response<List<Notification>> GetNotificationList(Player player, bool all)
        {
            StoredProcedure = "usp_GetNotifications";
            List<Notification> notifs = new List<Notification>();
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddParam("all", all);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();

                        //read the notif list, if an error occurred in the stored procedure there will be no results to read an this will be skipped
                        //Call the ModelFactory to build the model from the data
                        ModelFactory factory = new ModelFactory(Reader);
                        while (Reader.Read())
                        {
                            Notification notification = factory.NotificationFactory();
                            //If an error occurred while trying to build the notification list
                            if (notification == null)
                                return new Response<List<Notification>>("An error occurred while trying to build the notification list.", ErrorCodes.BUILD_MODEL_ERROR);

                            notifs.Add(notification);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<List<Notification>>(notifs, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<List<Notification>>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Leaves a player from the game.
        /// </summary>
        /// <param name="player">The player leaving the game.</param>
        /// <param name="isGameCompleted">The output param which outlines if the game is now complete after removing the player</param>
        /// <param name="isPhotosCompleted">The output param which outlines if photos have now finished voting after the player leaves.</param>
        /// <returns>A list of photos which have been completed after the player leaves.</returns>
        public Response<List<Photo>> LeaveGame(Player player, ref bool isGameCompleted, ref bool isPhotosCompleted)
        {
            StoredProcedure = "usp_LeaveGame";
            List<Photo> photos = new List<Photo>();
            isGameCompleted = false;
            isPhotosCompleted = false;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddOutput("isGameCompleted", SqlDbType.Bit);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        ModelFactory factory = new ModelFactory(Reader);
                        while (Reader.Read())
                        {
                            Photo photo = factory.PhotoFactory(true, true, true);
                            if (photo == null)
                                return new Response<List<Photo>>("An error occurred while trying to build the list photo model.", ErrorCodes.BUILD_MODEL_ERROR);

                            photos.Add(photo);
                        }
                        Reader.Close();
                        
                        ReadDefaultParams();
                        isGameCompleted = Convert.ToBoolean(Command.Parameters["@isGameCompleted"].Value);

                        //Format the results into a response object
                        Response<List<Photo>> response = new Response<List<Photo>>(photos, ErrorMSG, Result);

                        //If there is photos in the list then photo voting has been completed since the player left.
                        if (photos.Count != 0)
                            isPhotosCompleted = true;

                        return response;
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<List<Photo>>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Removes the unverified player from the game.
        /// </summary>
        /// <param name="hostPlayer">The host player of the game.</param>
        /// <param name="playerToRemove">The unverified player to remove.</param>
        /// <returns>The updated player record of the removed player.</returns>
        public Response<Player> RemoveUnverifiedPlayer(Player hostPlayer, Player playerToRemove)
        {
            StoredProcedure = "usp_RemoveUnverifiedPlayer";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", hostPlayer.PlayerID);
                        AddParam("playerIDToRemove", playerToRemove.PlayerID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        ModelFactory factory = new ModelFactory(Reader);
                        while (Reader.Read())
                        {
                            playerToRemove = factory.PlayerFactory(false);
                            if (playerToRemove == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(playerToRemove, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }





        /// <summary>
        /// Marks a players notifications as read.
        /// </summary>
        /// <param name="jsonNotificationIDs">The ID's of notifications to set as read.</param>
        /// <returns>Success or error.</returns>
        public Response SetNotificationsRead(ReadNotificationsRequest jsonNotificationIDs)
        {
            StoredProcedure = "usp_SetNotificationsRead";
            try
            {
                DataTable dt = new DataTable();
                dt.Columns.Add("notificationID");
                for (int i = 0; i < jsonNotificationIDs.NotificationArray.Length; i++)
                {
                    dt.Rows.Add(jsonNotificationIDs.NotificationArray[i]);
                }

                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", jsonNotificationIDs.PlayerID);
                        AddParam("udtNotifs", dt);
                        AddDefaultParams();
                        
                        //Perform the procedure and get the result
                        Run();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response(ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response.DatabaseErrorResponse();
            }
        }




        /// <summary>
        /// Decrements a players ammo count.
        /// </summary>
        /// <param name="player">The player to decrement</param>
        /// <returns>The updated player object</returns>
        public Response<Player> UseAmmo(Player player)
        {
            StoredProcedure = "usp_UseAmmo";
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
                            player = new ModelFactory(Reader).PlayerFactory(true);
                            if(player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }





        /// <summary>
        /// Replenish a players ammo count. Incrementing by 1.
        /// </summary>
        /// <param name="player">The player to update</param>
        /// <returns>The updated player object.</returns>
        public Response<Player> ReplenishAmmo(Player player)
        {
            StoredProcedure = "usp_ReplenishAmmo";
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
                            player = new ModelFactory(Reader).PlayerFactory(false);
                            if (player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// Gets the ammo count for the player.
        /// </summary>
        /// <param name="player">The Player</param>
        /// <returns>The ammo count, negative INT if an error occurred.</returns>
        public Response<int> GetAmmoCount(Player player)
        {
            StoredProcedure = "usp_GetAmmoCount";
            int ammoCount = -1;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddOutput("ammoCount", SqlDbType.Int);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        Run();
                        
                        //Format the results into a response object
                        ReadDefaultParams();
                        ammoCount = Convert.ToInt32(Command.Parameters["@ammoCount"].Value);
                        return new Response<int>(ammoCount, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<int>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// Gets the count of unread notifications
        /// </summary>
        /// <param name="player">The player getting the count for</param>
        /// <returns>The count of unread notifications, negative INT if an error occurred.</returns>
        public Response<int> GetUnreadNotificationsCount(Player player)
        {
            StoredProcedure = "usp_GetUnreadNotificationCount";
            int count = -1;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddOutput("count", SqlDbType.Int);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        Run();

                        //Format the results into a response object
                        ReadDefaultParams();
                        count = Convert.ToInt32(Command.Parameters["@count"].Value);
                        return new Response<int>(count, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<int>.DatabaseErrorResponse();
            }
        }





        /// <summary>
        /// Disables or Re-enables a player in a BR game.
        /// If the player is disabled they will be re-enabled and vice versa.
        /// </summary>
        /// <param name="player">The player being enabled or re-enabled</param>
        /// <param name="disabledForMinutes">The number of minutes the player is disabled.</param>
        /// <returns>The updated player record.</returns>
        public Response<Player> BR_DisableOrRenablePlayer(Player player, int disabledForMinutes)
        {
            StoredProcedure = "usp_BR_DisablePlayer";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddParam("isAlreadyDisabled", player.IsDisabled);
                        AddParam("disabledForMinutes", disabledForMinutes);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            player = new ModelFactory(Reader).PlayerFactory(true);
                            if (player == null)
                                return new Response<Player>("An error occurred while trying to build the player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Player>(player, ErrorMSG, Result);
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Player>.DatabaseErrorResponse();
            }
        }
    }
}
