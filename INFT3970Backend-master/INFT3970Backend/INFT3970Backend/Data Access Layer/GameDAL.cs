///-----------------------------------------------------------------
///   Class:        GameDAL
///   
///   Description:  The DataAccessLayer for all Game updates in the database.
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

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using INFT3970Backend.Models;
using INFT3970Backend.Models.Responses;

namespace INFT3970Backend.Data_Access_Layer
{
    public class GameDAL : DataAccessLayer
    {
        /// <summary>
        /// Creates a new game in the database.
        /// </summary>
        /// <param name="game">The game to add to the database.</param>
        /// <returns>The created game object added to the DB</returns>
        public Response<Game> CreateGame(Game game)
        {
            StoredProcedure = "usp_CreateGame";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameCode", game.GameCode);
                        AddParam("timeLimit", game.TimeLimit);
                        AddParam("ammoLimit", game.AmmoLimit);
                        AddParam("startDelay", game.StartDelay);
                        AddParam("replenishAmmoDelay", game.ReplenishAmmoDelay);
                        AddParam("gameMode", game.GameMode);
                        AddParam("isJoinableAtAnytime", game.IsJoinableAtAnytime);
                        AddParam("latitude", game.Latitude);
                        AddParam("longitude", game.Longitude);
                        AddParam("radius", game.Radius);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while (Reader.Read())
                        {
                            game = new ModelFactory(Reader).GameFactory();
                            if (game == null)
                                return new Response<Game>("An error occurred while trying to build the Game model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Game>(game, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<Game>.DatabaseErrorResponse();
            }
        }



        


        /// <summary>
        /// Deactivates / deletes the created game after the host player failed
        /// to join the game due to an error.
        /// </summary>
        /// <param name="game">The game being deactivated.</param>
        public void DeactivateGameAfterHostJoinError(Game game)
        {
            StoredProcedure = "usp_DeactivateGameAfterHostJoinError";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameID", game.GameID);
                        AddDefaultParams();
                        
                        //Perform the procedure and get the result
                        Run();
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                //Do nothing
            }
        }

        





        /// <summary>
        /// Gets the Game object matching the specified GameID
        /// </summary>
        /// <param name="gameID">The gameID of the game</param>
        /// <returns>Game object matching the specified ID.</returns>
        public Response<Game> GetGameByID(int gameID)
        {
            StoredProcedure = "usp_GetGameByID";
            Game game = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameID", gameID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        while(Reader.Read())
                        {
                            game = new ModelFactory(Reader).GameFactory();
                            if(game == null)
                                return new Response<Game>("An error occurred while trying to build the Game model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Game>(game, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<Game>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Creates a notification of type JOIN for all players in the game.
        /// Notifying them that a new player has joined the game.
        /// </summary>
        /// <param name="player">The player who joined the game.</param>
        public void CreateJoinNotification(Player player)
        {
            StoredProcedure = "usp_CreateJoinNotification";
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
                        Run();
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                //Do nothing
            }
        }





        /// <summary>
        /// Creates a notification of type LEAVE for all players in the game.
        /// Notifying them that a player has left the game.
        /// </summary>
        /// <param name="player">The player who left the game.</param>
        public void CreateLeaveNotification(Player player)
        {
            StoredProcedure = "usp_CreateLeaveNotification";
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
                        Run();
                        
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                Console.WriteLine("Leave Game Failed");
                //Do Nothing
            }
        }






        /// <summary>
        /// Creates a notification of type AMMO, sent a specific player.
        /// Notifying them that their ammo has been replenished from an empty state.
        /// </summary>
        /// <param name="player">The player who left the game.</param>
        public Response CreateAmmoNotification(Player player)
        {
            StoredProcedure = "usp_CreateAmmoNotification";
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
        /// Ends the game lobby after the host player left the game while the game
        /// is InLobby state. This is because only the host player can start the game
        /// so if the host leaves the lobby no player can start the game.
        /// </summary>
        /// <param name="game">The game being ended.</param>
        /// <returns>Success or error.</returns>
        public Response EndLobby(Game game)
        {
            StoredProcedure = "usp_EndLobby";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameID", game.GameID);
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
        /// Creates a notification of type SUCCESS or FAIL for all players in the game.
        /// Notifies all players that a tag was successful or unsuccessful. 
        /// </summary>
        /// <param name="photo">The photo which has now been completed.</param>
        /// <param name="isBR">A flag which outlines if the request is for a BR game.</param>
        public void CreateTagResultNotification(Photo photo, bool isBR)
        {
            if(isBR)
                StoredProcedure = "usp_BR_CreateTagResultNotification";
            else
                StoredProcedure = "usp_CreateTagResultNotification";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("takenByID", photo.TakenByPlayerID);
                        AddParam("photoOfID", photo.PhotoOfPlayerID);
                        AddParam("decision", photo.IsSuccessful);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        Run();
                        ReadDefaultParams();
                    }
                }
            }

            //A database exception was thrown, return an error response
            catch
            {
                //Do nothing
            }
        }







        /// <summary>
        /// Completes a game. Deactivating all records associated with the game.
        /// </summary>
        /// <param name="gameID">The ID of the Game to Complete</param>
        /// <returns>Success or error.</returns>
        public Response CompleteGame(int gameID)
        {
            StoredProcedure = "usp_CompleteGame";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameID", gameID);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        Run();

                        //Build the response object
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
        /// Gets all the players in a game with multiple filter parameters
        /// 
        /// FILTER
        /// ALL = get all the players in the game which arnt deleted
        /// ACTIVE = get all players in the game which arnt deleted and is active
        /// INGAME = get all players in the game which arnt deleted, is active, have not left the game and have been verified
        /// INGAMEALL = get all players in the game which arnt deleted, is active, and have been verified(includes players who have left the game)
        /// TAGGABLE = get all players in the game which arnt deleted, is active, have been verified, have not left game, have not been eliminated and is not the playerID making the request.
        ///
        /// ORDER by
        /// AZ = Order by name in alphabetical order
        /// ZA = Order by name in reverse alphabetical order
        /// KILLS= Order from highest to lowest in number of kills
        /// </summary>
        /// <param name="id">The playerID or the GameID</param>
        /// <param name="isPlayerID">A flag which outlines if the ID passed in is a playerID</param>
        /// <param name="filter">The filter value, ALL, ACTIVE, INGAME, INGAMEALL</param>
        /// <param name="orderBy">The order by value, AZ, ZA, KILLS</param>
        /// <returns>The list of all players in the game</returns>
        public Response<Game> GetAllPlayersInGame(int id, bool isPlayerID, string filter, string orderBy)
        {
            StoredProcedure = "usp_GetAllPlayersInGame";
            List<Player> players = new List<Player>();
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("id", id);
                        AddParam("isPlayerID", isPlayerID);
                        AddParam("filter", filter);
                        AddParam("orderBy", orderBy);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();

                        //read the player list, if an error occurred in the stored procedure there will be no results to read an this will be skipped
                        ModelFactory factory = new ModelFactory(Reader);
                        while (Reader.Read())
                        {
                            //Call the ModelFactory to build the model from the data
                            Player player = factory.PlayerFactory(false);

                            //If an error occurred while trying to build the player list
                            if (player == null)
                                return new Response<Game>("An error occurred while trying to build the player list.", ErrorCodes.BUILD_MODEL_ERROR);

                            players.Add(player);
                        }
                        Reader.Close();
                        
                        ReadDefaultParams();

                        //If the response was not successful return the empty response
                        if(IsError)
                            return new Response<Game>(ErrorMSG, Result);
                    }
                }

                //If the players list is empty, return an error
                if(players.Count == 0)
                    return new Response<Game>("The players list is empty.", ErrorCodes.ITEM_DOES_NOT_EXIST);

                //Get the Game object
                Response<Game> gameResponse = GetGameByID(players[0].GameID);

                //If the Game response was not successful, return an error
                if(!gameResponse.IsSuccessful())
                    return new Response<Game>(gameResponse.ErrorMessage, gameResponse.ErrorCode);

                //Otherwise, create the successful response with the game and player list
                gameResponse.Data.Players = players;
                return new Response<Game>(gameResponse.Data, ErrorMSG, Result);
            }

            //A database exception was thrown, return an error response
            catch
            {
                return Response<Game>.DatabaseErrorResponse();
            }
        }







        /// <summary>
        /// Sets the Game State to starting in the database, updates the game start time to the
        /// current time plus the start delay in the future and sets the Game end time. After this method is run code will be scheduled
        /// in the business logic to update the game to playing, then also update the game to be completed.
        /// </summary>
        /// <param name="player">The host player beginning the game.</param>
        /// <returns>The updated game object.</returns>
        public Response<Game> BeginGame(Player player)
        {
            StoredProcedure = "usp_BeginGame";
            Game game = null;
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
                            game = new ModelFactory(Reader).GameFactory();
                            if(game == null)
                                return new Response<Game>("An error occurred while trying to build the Game model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        return new Response<Game>(game, ErrorMSG, Result);
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<Game>.DatabaseErrorResponse();
            }
        }






        /// <summary>
        /// Sets the GameState to the state passed in.
        /// </summary>
        /// <param name="gameID">The ID of the game to update</param>
        /// <param name="gameState">The new state to set.</param>
        /// <returns>Success or error.</returns>
        public Response SetGameState(int gameID, string gameState)
        {
            StoredProcedure = "usp_SetGameState";
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("gameID", gameID);
                        AddParam("gameState", gameState);
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
        /// Get the current status of the game / web application. Used when a user reconnects
        /// back to the web application in order to the front end to be updated with the current
        /// game / application state so the front end can redirect the user accordingly.
        /// </summary>
        /// <param name="player">The player making the request.</param>
        /// <returns>
        /// A GameStatusResponse object which outlines the GameState, 
        /// if the player has votes to complete, if the player has any new notifications 
        /// and the most recent player record. NULL if an error occurred.
        /// </returns>
        public Response<GameStatusResponse> GetGameStatus(Player player)
        {
            StoredProcedure = "usp_GetGameStatus";
            Response<GameStatusResponse> response = null;
            try
            {
                //Create the connection and command for the stored procedure
                using (Connection = new SqlConnection(ConnectionString))
                {
                    using (Command = new SqlCommand(StoredProcedure, Connection))
                    {
                        //Add the procedure input and output params
                        AddParam("playerID", player.PlayerID);
                        AddOutput("hasVotesToComplete", SqlDbType.Bit);
                        AddOutput("hasNotifications", SqlDbType.Bit);
                        AddDefaultParams();

                        //Perform the procedure and get the result
                        RunReader();
                        Player updatedPlayer = null;
                        while(Reader.Read())
                        {
                            updatedPlayer = new ModelFactory(Reader).PlayerFactory(true);
                            if(player == null)
                                return new Response<GameStatusResponse>("An error occurred while trying to build the Player model.", ErrorCodes.BUILD_MODEL_ERROR);
                        }
                        Reader.Close();

                        //Format the results into a response object
                        ReadDefaultParams();
                        response = new Response<GameStatusResponse>(null, ErrorMSG, Result);

                        //If the result is not an error build the GameStatus object and assign it to the response
                        if(!IsError)
                        {
                            bool hasVotesToComplete = Convert.ToBoolean(Command.Parameters["@hasVotesToComplete"].Value);
                            bool hasNotifications = Convert.ToBoolean(Command.Parameters["@hasNotifications"].Value);
                            GameStatusResponse gsr = new GameStatusResponse(hasVotesToComplete, hasNotifications, updatedPlayer);
                            response.Data = gsr;
                        }
                        return response;
                    }
                }
            }
            //A database exception was thrown, return an error response
            catch
            {
                return Response<GameStatusResponse>.DatabaseErrorResponse();
            }
        }
    }
}
